# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DorController, type: :controller do
  let(:druid) { 'druid:aa111bb2222' }

  before do
    sign_in(create(:user))
  end

  describe 'reindex' do
    context 'from a show page' do
      it 'redirects to show page and set flash notice on success' do
        expect(Argo::Indexer).to receive(:reindex_pid_remotely).with(druid)
        get :reindex, params: { pid: druid }
        expect(flash[:notice]).to eq "Successfully updated index for #{druid}"
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(solr_document_path(druid))
      end

      it 'redirects to show page and sets flash error on failure' do
        expect(Argo::Indexer).to receive(:reindex_pid_remotely).with(druid).and_raise(Argo::Exceptions::ReindexError)
        expect(Rails.logger).to receive(:error).with(/Failed to update index for #{druid}/)
        get :reindex, params: { pid: druid }
        expect(flash[:error]).to eq "Failed to update index for #{druid}"
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(solr_document_path(druid))
      end
    end
  end
end
