# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Draw the manage release form' do
  let(:item) do
    instance_double(Dor::Item, pid: 'druid:bc123df4567')
  end
  let(:document) do
    instance_double(SolrDocument,
                    id: 'druid:bc123df4567',
                    object_type: 'item',
                    title: 'My item',
                    released_to: ['Searchworks'])
  end

  let(:user) { create(:user) }

  before do
    allow(Dor).to receive(:find).with('druid:bc123df4567').and_return(item)
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
