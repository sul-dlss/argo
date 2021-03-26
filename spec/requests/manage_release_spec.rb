# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Draw the manage release form' do
  let(:document) do
    instance_double(SolrDocument,
                    id: 'druid:bc123df4567',
                    object_type: 'item',
                    title: 'My item',
                    released_to: ['Searchworks'])
  end

  let(:user) { create(:user) }
  let(:pid) { 'druid:bc123df4567' }
  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model) }
  let(:cocina_model) do
    Cocina::Models.build(
      'label' => 'The item',
      'version' => 1,
      'type' => Cocina::Models::Vocab.object,
      'externalIdentifier' => pid,
      'access' => {
        'access' => 'world'
      },
      'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
      'structural' => {},
      'identification' => {}
    )
  end

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
