# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DescriptiveMetadataImportJob do
  subject(:job) { described_class.new(bulk_action.id, csv_file:) }

  let(:druid) { 'druid:bc123df4567' }
  let(:cocina_object) { build(:dro_with_metadata, id: druid) }

  let(:expected_cocina_object) do
    cocina_object.new(description: cocina_object.description.new(title: [{ value: 'new title 1' }], purl: "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}"))
  end

  let(:bulk_action) { create(:bulk_action) }
  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_object) }
  let(:log) { StringIO.new }

  let(:job_item) do
    described_class::DescriptiveMetadataImportJobItem.new(druid: druid, index: 2, job: job, row:).tap do |job_item|
      allow(job_item).to receive(:open_new_version_if_needed!)
      allow(job_item).to receive(:check_update_ability?).and_return(true)
      allow(job_item).to receive(:close_version_if_needed!)
    end
  end

  let(:purl) { "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}" }
  let(:csv_file) do
    [
      'druid,source_id,title1:value,purl',
      [druid, cocina_object.identification.sourceId, 'new title 1', purl].join(',')
    ].join("\n")
  end

  let(:row) { CSV.parse(csv_file, headers: true).first }

  before do
    allow(described_class::DescriptiveMetadataImportJobItem).to receive(:new).and_return(job_item)
    allow_any_instance_of(BulkAction).to receive(:open_log_file).and_return(log) # rubocop:disable RSpec/AnyInstance
    allow(Repository).to receive(:store)
    allow(Dor::Services::Client.objects).to receive(:indexable)
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
  end

  it 'performs the job' do
    job.perform_now

    expect(described_class::DescriptiveMetadataImportJobItem)
      .to have_received(:new).with(druid: druid, index: 2, job: job, row:)

    expect(job_item).to have_received(:check_update_ability?)
    expect(Dor::Services::Client.objects).to have_received(:indexable).with(druid:, cocina: expected_cocina_object)
    expect(job_item).to have_received(:open_new_version_if_needed!).with(description: 'Descriptive metadata upload')
    expect(Repository).to have_received(:store).with(expected_cocina_object)
    expect(job_item).to have_received(:close_version_if_needed!)

    expect(bulk_action.reload.druid_count_total).to eq(1)
    expect(bulk_action.druid_count_success).to eq(1)
    expect(bulk_action.druid_count_fail).to eq(0)
  end

  context 'when the user is not authorized to update' do
    before do
      allow(job_item).to receive(:check_update_ability?).and_return(false)
    end

    it 'does not update the descriptive metadata' do
      job.perform_now

      expect(job_item).not_to have_received(:open_new_version_if_needed!)
      expect(Repository).not_to have_received(:store)
    end
  end

  context 'when validation fails' do
    let(:csv_file) do
      [
        'druid,source_id,title1.structuredValue1.value,purl',
        [druid, cocina_object.identification.sourceId, 'new title 1', purl].join(',')
      ].join("\n")
    end

    it 'does not update the descriptive metadata' do
      job.perform_now

      expect(job_item).not_to have_received(:open_new_version_if_needed!)
      expect(Repository).not_to have_received(:store)

      expect(log.string).to include 'Missing type for value in description'

      expect(bulk_action.reload.druid_count_total).to eq 1
      expect(bulk_action.druid_count_fail).to eq 1
      expect(bulk_action.druid_count_success).to eq 0
    end
  end

  context 'when index validation fails' do
    let(:response) { instance_double(Faraday::Response, status: 422, body: nil, reason_phrase: 'Example field error') }

    before do
      allow(Dor::Services::Client.objects).to receive(:indexable).and_raise(Dor::Services::Client::UnprocessableContentError.new(response:))
    end

    it 'does not update the descriptive metadata' do
      job.perform_now

      expect(job_item).not_to have_received(:open_new_version_if_needed!)
      expect(Repository).not_to have_received(:store)

      expect(log.string).to include "indexing validation failed for #{druid}: Example field error"

      expect(bulk_action.reload.druid_count_total).to eq 1
      expect(bulk_action.druid_count_fail).to eq 1
      expect(bulk_action.druid_count_success).to eq 0
    end
  end

  context 'when unchanged' do
    let(:csv_file) do
      [
        'druid,source_id,title1:value,purl',
        [druid, cocina_object.identification.sourceId, 'factory DRO title', purl].join(',')
      ].join("\n")
    end

    it 'does not update the descriptive metadata' do
      job.perform_now

      expect(job_item).not_to have_received(:open_new_version_if_needed!)
      expect(Repository).not_to have_received(:store)

      expect(log.string).to include 'Description unchanged'

      expect(bulk_action.reload.druid_count_total).to eq 1
      expect(bulk_action.druid_count_fail).to eq 1
      expect(bulk_action.druid_count_success).to eq 0
    end
  end
end
