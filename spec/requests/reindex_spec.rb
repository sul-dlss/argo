# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Reindexing', type: :request do
  let(:druid) { 'druid:aa111bb2222' }

  before do
    sign_in(create(:user))
  end

  describe 'reindex' do
    before do
      allow(Argo::Indexer).to receive(:reindex_pid_remotely)
    end

    context 'from a show page' do
      it 'redirects to show page and set flash notice on success' do
        get "/dor/reindex/#{druid}"
        expect(flash[:notice]).to eq "Successfully updated index for #{druid}"
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(solr_document_path(druid))
        expect(Argo::Indexer).to have_received(:reindex_pid_remotely).with(druid)
      end

      it 'redirects to show page and sets flash error on failure' do
        allow(Argo::Indexer).to receive(:reindex_pid_remotely).and_raise(Argo::Exceptions::ReindexError)
        expect(Rails.logger).to receive(:error).with(/Failed to update index for #{druid}/)
        get "/dor/reindex/#{druid}"
        expect(flash[:error]).to eq "Failed to update index for #{druid}"
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(solr_document_path(druid))
      end
    end
  end
end
