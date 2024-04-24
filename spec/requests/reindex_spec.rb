# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Reindexing' do
  let(:druid) { 'druid:aa111bb2222' }
  let(:object_client) { instance_double(Dor::Services::Client::Object) }

  before do
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
    sign_in(create(:user))
  end

  describe 'reindex' do
    context 'from a show page on success' do
      before do
        allow(object_client).to receive(:reindex).and_return(true)
      end

      it 'redirects to show page and set flash notice' do
        get "/dor/reindex/#{druid}"
        expect(flash[:notice]).to eq "Successfully updated index for #{druid}"
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(solr_document_path(druid))
        expect(object_client).to have_received(:reindex)
      end
    end

    context 'from a show page on failure' do
      before do
        allow(object_client).to receive(:reindex).and_raise(Dor::Services::Client::UnexpectedResponse.new(response: '', errors: ['Ooops']))
      end

      it 'redirects to show page and sets flash error on failure' do
        expect(Rails.logger).to receive(:error).with(/Failed to update index for #{druid}/)
        get "/dor/reindex/#{druid}"
        expect(flash[:error]).to eq "Failed to update index for #{druid}"
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(solr_document_path(druid))
      end
    end
  end
end
