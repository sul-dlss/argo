# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActionHelper do
  describe '#render_bulk_action_type' do
    context 'with partial defined' do
      it 'renders the bulk actions partial' do
        bulk_action = create(:bulk_action, action_type: 'DescmetadataDownloadJob')
        expect(helper).to receive(:render)
          .with(
            partial: 'descmetadata_download_job',
            locals: { bulk_action: bulk_action }
          )
        helper.render_bulk_action_type(bulk_action)
      end
    end
  end

  describe '#search_of_pids' do
    context 'when nil' do
      it 'returns an empty string' do
        expect(helper.search_of_pids(nil)).to eq ''
      end
    end

    context 'when a Blacklight::Search' do
      it 'adds a pids_only param' do
        search = Search.new
        search.query_params = { q: 'cool catz' }
        expect(helper.search_of_pids(search)).to include(q: 'cool catz', 'pids_only' => true)
      end
    end
  end

  describe '#show_report_link?' do
    let(:bulk_action) { create(:bulk_action, action_type: 'ChecksumReportJob') }

    context 'when status completed and file exists' do
      before do
        allow(bulk_action).to receive(:status).and_return('Completed')
        allow(File).to receive(:exist?).and_return(true)
      end

      it 'returns true' do
        expect(helper.show_report_link?(bulk_action, Settings.checksum_report_job.csv_filename)).to be_truthy
      end
    end

    context 'when status completed but file does not exist' do
      before do
        allow(bulk_action).to receive(:status).and_return('Completed')
        allow(File).to receive(:exist?).and_return(false)
      end

      it 'returns false' do
        expect(helper.show_report_link?(bulk_action, Settings.checksum_report_job.csv_filename)).to be_falsey
      end
    end

    context 'when status not completed' do
      before do
        allow(bulk_action).to receive(:status).and_return('Processing')
      end

      it 'returns false' do
        expect(helper.show_report_link?(bulk_action, Settings.checksum_report_job.csv_filename)).to be_falsey
      end
    end
  end
end
