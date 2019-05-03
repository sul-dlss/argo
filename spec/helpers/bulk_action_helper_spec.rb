# frozen_string_literal: true

require 'spec_helper'

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
end
