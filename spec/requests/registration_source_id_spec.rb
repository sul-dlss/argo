# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Registration source_id check', type: :request do
  let(:user) { create(:user) }
  let(:blacklight_config) { CatalogController.blacklight_config }
  let(:solr_conn) { blacklight_config.repository_class.new(blacklight_config).connection }
  let(:source_id) { 'sul:abc-123' }

  before do
    sign_in user
    solr_conn.add(:id => 'druid:hv992yv2222', SolrDocument::FIELD_SOURCE_ID => source_id)
    solr_conn.commit
  end

  context 'when source_id found' do
    it 'returns true' do
      get "/registration/source_id?source_id=#{source_id}"

      expect(response.body).to eq('true')
    end
  end

  context 'when source_id not found' do
    it 'returns false' do
      get "/registration/source_id?source_id=x#{source_id}"

      expect(response.body).to eq('false')
    end
  end
end
