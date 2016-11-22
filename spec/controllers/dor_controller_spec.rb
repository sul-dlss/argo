require 'spec_helper'

describe DorController, :type => :controller do
  let(:druid) { 'druid:aa111bb2222' }
  before :each do
    log_in_as_mock_user(subject)
  end
  describe 'reindex' do
    context 'from a show page' do
      it 'redirects to show page and set flash notice on success' do
        expect(Dor::IndexingService).to receive(:reindex_pid_remotely).with(druid)
        get :reindex, params: { pid: druid }
        expect(flash[:notice]).to eq "Successfully updated index for #{druid}"
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(catalog_path(druid))
      end

      it 'redirects to show page and sets flash error on failure' do
        expect(Dor::IndexingService).to receive(:reindex_pid_remotely).with(druid).and_raise(Dor::IndexingService::ReindexError)
        expect(Rails.logger).to receive(:error).with(/Failed to update index for #{druid}/)
        get :reindex, params: { pid: druid }
        expect(flash[:error]).to eq "Failed to update index for #{druid}"
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(catalog_path(druid))
      end
    end
    context 'from bulk action' do
      it 'returns success code and message on success' do
        expect(Dor::IndexingService).to receive(:reindex_pid_remotely).with(druid)
        get :reindex, params: { pid: druid, bulk: 'true' }
        expect(response.body).to eq "Successfully updated index for #{druid}"
        expect(response).to have_http_status(:ok)
      end

      it 'returns error code and message on failure' do
        expect(Dor::IndexingService).to receive(:reindex_pid_remotely).with(druid).and_raise(Dor::IndexingService::ReindexError)
        expect(Rails.logger).to receive(:error).with(/Failed to update index for #{druid}/)
        get :reindex, params: { pid: druid, bulk: 'true' }
        expect(response.body).to eq "Failed to update index for #{druid}"
        expect(response).to have_http_status(:internal_server_error)
      end
    end
  end

  describe 'republish' do
    it 'should republish' do
      mock_item = double()
      expect(mock_item).to receive(:publish_metadata_remotely)
      expect(Dor).to receive(:find).and_return(mock_item)
      get :republish, params: { pid: druid }
      expect(response).to have_http_status(:found)
    end
  end
end
