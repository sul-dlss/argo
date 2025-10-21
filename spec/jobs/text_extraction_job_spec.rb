# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TextExtractionJob do
  subject(:job) { described_class.new(bulk_action.id, druids: [druid], text_extraction_languages: languages) }

  let(:bulk_action) { create(:bulk_action) }
  let(:druid) { 'druid:bb111cc2222' }
  let(:cocina_object) { instance_double(Cocina::Models::DRO) }
  let(:languages) { ['English'] }
  let(:log) { StringIO.new }

  let(:job_item) do
    described_class::TextExtractionJobItem.new(druid: druid, index: 0, job: job).tap do |job_item|
      allow(job_item).to receive_messages(check_update_ability?: true, cocina_object: cocina_object)
    end
  end

  let(:version_service) { instance_double(VersionService, open?: false, assembling?: false) }
  let(:text_extraction) { instance_double(TextExtraction, start: true, possible?: true, wf_name: 'ocrWF') }

  before do
    allow(described_class::TextExtractionJobItem).to receive(:new).and_return(job_item)
    allow(VersionService).to receive(:new).and_return(version_service)
    allow(TextExtraction).to receive(:new).and_return(text_extraction)
    allow_any_instance_of(BulkAction).to receive(:open_log_file).and_return(log) # rubocop:disable RSpec/AnyInstance
  end

  it 'performs the job' do
    job.perform_now

    expect(job_item).to have_received(:check_update_ability?)

    expect(VersionService).to have_received(:new).with(druid:)
    expect(TextExtraction).to have_received(:new).with(cocina_object, languages:, already_opened: false)
    expect(text_extraction).to have_received(:start)

    expect(log.string).to include('ocrWF successfully started')

    expect(bulk_action.reload.druid_count_total).to eq 1
    expect(bulk_action.druid_count_success).to eq 1
    expect(bulk_action.druid_count_fail).to eq 0
  end

  context 'when text extraction is not possible for the object' do
    before do
      allow(text_extraction).to receive(:possible?).and_return(false)
    end

    it 'records a failure' do
      job.perform_now

      expect(text_extraction).not_to have_received(:start)

      expect(bulk_action.reload.druid_count_total).to eq 1
      expect(bulk_action.druid_count_success).to eq 0
      expect(bulk_action.druid_count_fail).to eq 1

      expect(log.string).to include('Text extraction is not possible for this object')
    end
  end

  context 'when the object is currently assembling' do
    before do
      allow(version_service).to receive(:assembling?).and_return(true)
    end

    it 'records a failure' do
      job.perform_now

      expect(text_extraction).not_to have_received(:start)

      expect(bulk_action.reload.druid_count_total).to eq 1
      expect(bulk_action.druid_count_success).to eq 0
      expect(bulk_action.druid_count_fail).to eq 1

      expect(log.string).to include('Object is currently assembling')
    end
  end

  context 'when the user is not authorized to update the object' do
    before do
      allow(job_item).to receive(:check_update_ability?).and_return(false)
    end

    it 'does not start text extraction' do
      job.perform_now

      expect(text_extraction).not_to have_received(:start)
    end
  end
end
