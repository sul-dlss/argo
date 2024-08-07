# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Draw the manage release form' do
  let(:document) do
    SolrDocument.new(id: 'druid:bc123df4567',
                     SolrDocument::FIELD_OBJECT_TYPE => 'item',
                     SolrDocument::FIELD_TITLE => 'My item',
                     SolrDocument::FIELD_RELEASED_TO => ['Searchworks'])
  end

  let(:user) { create(:user) }
  let(:druid) { 'druid:bc123df4567' }
  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model) }
  let(:cocina_model) { build(:dro_with_metadata, id: druid) }

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
  end

  context 'for content managers' do
    before do
      sign_in create(:user), groups: ['sdr:administrator-role']

      allow_any_instance_of(Blacklight::Solr::Repository).to receive(:find)
        .with('druid:bc123df4567', {})
        .and_return(instance_double(Blacklight::Solr::Response, documents: [document]))
    end

    it 'authorizes the view' do
      get '/items/druid:bc123df4567/manage_release'
      expect(response).to have_http_status(:success)
    end
  end

  context 'for unauthorized_user' do
    before do
      sign_in user
    end

    it 'returns forbidden' do
      get '/items/druid:bc123df4567/manage_release'
      expect(response).to have_http_status(:forbidden)
    end
  end
end
