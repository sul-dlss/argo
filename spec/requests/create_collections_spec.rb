# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create collections' do
  before do
    sign_in user, groups: ['sdr:administrator-role']
  end

  let(:apo_id) { 'druid:zt570qh4444' }
  let(:collection_id) { 'druid:bp475vb4486' }
  let(:user) { create(:user) }
  let(:collection) { instance_double(Cocina::Models::Collection, externalIdentifier: collection_id) }

  describe 'show the form' do
    let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model) }
    let(:cocina_model) do
      build(:admin_policy_with_metadata)
    end

    before do
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    end

    it 'is successful' do
      get "/collections/new?modal=true&apo_druid=#{apo_id}"
      expect(response).to be_successful
    end
  end

  describe 'save the form' do
    let(:form) { instance_double(CollectionForm, validate: true, save: true, model: collection) }
    let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model, update: true, reindex: true) }
    let(:cocina_model) do
      build(:admin_policy_with_metadata)
    end
    let(:version_service) { instance_double(VersionService, open?: false, openable?: true, open: cocina_model, close: true) }

    before do
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
      allow(VersionService).to receive(:new).and_return(version_service)
      allow(CollectionForm).to receive(:new).and_return(form)
    end

    it 'creates a collection using the form' do
      post '/collections', params: {
        'apo_druid' => apo_id,
        'modal' => 'true',
        'label' => ':auto',
        'collection_catalog_record_id' => '1234567',
        'collection_rights_catalog_record_id' => 'dark'
      }
      expect(response).to be_redirect # redirects to catalog page
      expect(form).to have_received(:save)
      expect(object_client).to have_received(:update).with(params: cocina_admin_policy_with_registration_collections([collection_id]))
      expect(version_service).to have_received(:open)
      expect(version_service).to have_received(:close)
    end
  end

  describe "check that it's not a duplicate" do
    let(:title) { 'foo' }
    let(:catalog_record_id) { '123' }
    let(:repo) { instance_double(Blacklight::Solr::Repository, connection: solr_client) }
    let(:solr_client) { instance_double(RSolr::Client, get: result) }

    before do
      allow(Blacklight::Solr::Repository).to receive(:new).and_return(repo)
    end

    context 'when the title is provided and the collection exists' do
      let(:result) { { 'response' => { 'numFound' => 1 } } }

      it 'returns true' do
        get "/collections/exists?title=#{title}"
        expect(response.body).to eq('true')
        expect(solr_client).to have_received(:get).with('select', params: a_hash_including(
          q: "_query_:\"{!raw f=#{SolrDocument::FIELD_OBJECT_TYPE}}collection\" AND obj_label_tesim:\"foo\""
        ))
      end
    end

    context 'when the title is provided and the collection does not exist' do
      let(:result) { { 'response' => { 'numFound' => 0 } } }

      it 'returns false' do
        get "/collections/exists?title=#{title}"
        expect(response.body).to eq('false')
      end
    end

    context 'when the catalog_record_id is provided and the collection exists' do
      let(:result) { { 'response' => { 'numFound' => 1 } } }

      it 'returns true' do
        get "/collections/exists?catalog_record_id=#{catalog_record_id}"
        expect(response.body).to eq('true')
        expect(solr_client).to have_received(:get).with('select', params: a_hash_including(
          q: "_query_:\"{!raw f=#{SolrDocument::FIELD_OBJECT_TYPE}}collection\" AND identifier_ssim:\"#{CatalogRecordId.indexing_prefix}:123\""
        ))
      end
    end

    context 'when the catalog_record_id is provided and the collection does not exist' do
      let(:result) { { 'response' => { 'numFound' => 0 } } }

      it 'returns false' do
        get "/collections/exists?catalog_record_id=#{catalog_record_id}"
        expect(response.body).to eq('false')
      end
    end

    context 'when the title and catalog_record_id is provided and the collection exists' do
      let(:result) { { 'response' => { 'numFound' => 1 } } }

      it 'returns true if collection with title and catalog_record_id exists' do
        get "/collections/exists?catalog_record_id=#{catalog_record_id}&title=#{title}"
        expect(response.body).to eq('true')
        expect(solr_client).to have_received(:get).with('select', params: a_hash_including(
          q: "_query_:\"{!raw f=#{SolrDocument::FIELD_OBJECT_TYPE}}collection\" AND obj_label_tesim:\"foo\" AND identifier_ssim:\"#{CatalogRecordId.indexing_prefix}:123\""
        ))
      end
    end
  end
end
