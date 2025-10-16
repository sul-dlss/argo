# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ValidateCocinaDescriptiveJob do
  subject(:job) { described_class.new(bulk_action.id, csv_file:) }

  let(:bulk_action) { create(:bulk_action) }
  let(:druid) { 'druid:bb111cc2222' }

  let(:job_item) do
    described_class::ValidateCocinaDescriptiveJobItem.new(druid: druid, index: 2, job: job, row:).tap do |job_item|
      allow(job_item).to receive(:cocina_object).and_return(cocina_object)
    end
  end

  let(:cocina_object) { build(:dro, id: druid) }
  let(:log) { instance_double(File, puts: nil, close: true) }

  let(:csv_file) do
    [
      'druid,source_id,title1:value,purl',
      [cocina_object.externalIdentifier, cocina_object.identification.sourceId, 'new title 1', 'https://purl/bb111cc2222'].join(',')
    ].join("\n")
  end

  let(:row) { CSV.parse(csv_file, headers: true).first }

  before do
    allow_any_instance_of(BulkAction).to receive(:open_log_file).and_return(log) # rubocop:disable RSpec/AnyInstance
    allow(described_class::ValidateCocinaDescriptiveJobItem).to receive(:new).and_return(job_item)
  end

  it 'performs the job' do
    job.perform_now

    expect(bulk_action.reload.druid_count_total).to eq 1
    expect(bulk_action.druid_count_fail).to eq 0
    expect(bulk_action.druid_count_success).to eq 1
  end

  context 'when invalid cocina metadata' do
    let(:csv_file) do
      [
        'druid,source_id,title1.structuredValue1.type,purl',
        [cocina_object.externalIdentifier, cocina_object.identification.sourceId, 'new title 1', 'https://purl/bb111cc2222'].join(',')
      ].join("\n")
    end

    it 'returns a failure' do
      job.perform_now

      expect(log).to have_received(:puts).with(/Unrecognized types in description: title1.structuredValue1 \(new title 1\)/)

      expect(bulk_action.reload.druid_count_total).to eq 1
      expect(bulk_action.druid_count_fail).to eq 1
      expect(bulk_action.druid_count_success).to eq 0
    end
  end
end
