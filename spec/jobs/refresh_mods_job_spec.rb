# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RefreshModsJob do
  subject(:job) { described_class.new(bulk_action.id, druids: [druid]) }

  let(:druid) { 'druid:bb111cc2222' }
  let(:bulk_action) { create(:bulk_action) }

  let(:job_item) do
    described_class::RefreshModsJobItem.new(druid: druid, index: 0, job: job).tap do |job_item|
      allow(job_item).to receive(:open_new_version_if_needed!)
      allow(job_item).to receive(:close_version_if_needed!)
      allow(job_item).to receive_messages(check_update_ability?: true, cocina_object: cocina_object)
    end
  end
  let(:cocina_object) do
    build(:dro_with_metadata, id: druid, folio_instance_hrids: ['a123'])
  end

  let(:object_client) do
    instance_double(Dor::Services::Client::Object, refresh_descriptive_metadata_from_ils: true)
  end

  let(:log) { instance_double(File, puts: nil, close: true) }

  before do
    allow(described_class::RefreshModsJobItem).to receive(:new).and_return(job_item)
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
    allow_any_instance_of(BulkAction).to receive(:open_log_file).and_return(log) # rubocop:disable RSpec/AnyInstance
  end

  it 'performs the job' do
    job.perform_now

    expect(job_item).to have_received(:check_update_ability?)
    expect(job_item).to have_received(:open_new_version_if_needed!).with(description: 'Refreshed metadata from FOLIO')
    expect(object_client).to have_received(:refresh_descriptive_metadata_from_ils)
    expect(job_item).to have_received(:close_version_if_needed!)

    expect(bulk_action.reload.druid_count_total).to eq(1)
    expect(bulk_action.druid_count_fail).to eq(0)
    expect(bulk_action.druid_count_success).to eq(1)
  end

  context 'when catalog_record_id is missing' do
    let(:cocina_object) { build(:dro_with_metadata, id: druid) }

    it 'does not refresh the metadata' do
      job.perform_now

      expect(object_client).not_to have_received(:refresh_descriptive_metadata_from_ils)

      expect(log).to have_received(:puts).with(/Does not have a Folio Instance HRID for #{druid}/)

      expect(bulk_action.reload.druid_count_total).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(1)
      expect(bulk_action.druid_count_success).to eq(0)
    end
  end

  context 'when the user lacks update ability' do
    before do
      allow(job_item).to receive(:check_update_ability?).and_return(false)
    end

    it 'does not refresh the metadata' do
      job.perform_now

      expect(object_client).not_to have_received(:refresh_descriptive_metadata_from_ils)
    end
  end
end
