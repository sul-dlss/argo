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
end
