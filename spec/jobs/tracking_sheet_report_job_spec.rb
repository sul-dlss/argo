# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TrackingSheetReportJob do
  subject(:job) { described_class.new(bulk_action.id, druids: [druid]) }

  let(:druid) { 'druid:cc111dd2222' }

  let(:output_directory) { bulk_action.output_directory }
  let(:bulk_action) { create(:bulk_action) }

  let(:response) { { 'response' => { 'docs' => docs } } }
  let(:solr_doc) { { id: druid, SolrDocument::FIELD_TITLE => 'Some label' } }
  let(:docs) { [solr_doc] }

  before do
    allow(SearchService).to receive(:query)
      .with('id:"druid:cc111dd2222"', rows: 1)
      .and_return(response)
  end

  after do
    FileUtils.rm_rf(output_directory)
  end

  it 'performs the job' do
    subject.perform_now

    expect(File).to exist(File.join(output_directory, Settings.tracking_sheet_report_job.pdf_filename))

    expect(bulk_action.reload.druid_count_total).to eq(1)
    expect(bulk_action.druid_count_fail).to eq(0)
    expect(bulk_action.druid_count_success).to eq(1)
  end

  context 'when there is an error writing the PDF' do
    let(:pdf) { Prawn::Document.new(page_size: [5.5.in, 8.5.in]) }

    before do
      allow(Prawn::Document).to receive(:new).and_return(pdf)
      allow(pdf).to receive(:render_file).and_raise(StandardError)
    end

    it 'does not write the tracking sheet' do
      subject.perform_now

      expect(bulk_action.reload.druid_count_total).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(1)
      expect(bulk_action.druid_count_success).to eq(0)
    end
  end
end
