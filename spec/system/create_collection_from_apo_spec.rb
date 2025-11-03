# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Add collection from APO show page' do
  before do
    allow(Blacklight::Solr::Repository).to receive(:new).and_return(repo)
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    sign_in create(:user), groups: ['sdr:administrator-role']
  end

  let(:repo) { instance_double(Blacklight::Solr::Repository, connection: solr_client) }
  let(:solr_client) { instance_double(RSolr::Client, get: result) }
  let(:result) { { 'response' => { 'numFound' => 1 } } }
  let(:apo_druid) { 'druid:vt333hq2222' }
  let(:cocina_model) do
    instance_double(Cocina::Models::AdminPolicyWithMetadata, label: 'hey', externalIdentifier: apo_druid)
  end
  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model) }

  describe 'when collection catalog_record_id is provided', :js do
    it 'warns if catalog_record_id exists' do
      visit new_collection_path(apo_druid:, modal: true)
      choose "Create a Collection from #{CatalogRecordId.type.capitalize}"
      expect(page).to have_text("Collection #{CatalogRecordId.label}")
      expect(page).to have_no_text('already exists')
      fill_in 'collection_catalog_record_id', with: 'foo'
      expect(page).to have_text('already exists')
    end
  end

  describe 'when invalid FOLIO Collection HRID is provided', :js do
    let(:result) { { 'response' => { 'numFound' => 0 } } }

    it 'warns that catalog id is not formatted correctly' do
      visit new_collection_path(apo_druid:, modal: true)
      choose "Create a Collection from #{CatalogRecordId.type.capitalize}"
      expect(page).to have_text("Collection #{CatalogRecordId.label}")
      fill_in 'collection_catalog_record_id', with: '123'
      expect(page).to have_text('Collection Folio Instance HRID must be in an allowed format.')
      fill_in 'collection_catalog_record_id', with: 'a123'
      expect(page).to have_no_text('Collection Folio Instance HRID must be in an allowed format.')
    end
  end

  describe 'when collection title is provided', :js do
    it 'warns if title exists' do
      visit new_collection_path(apo_druid:, modal: true)
      expect(page).to have_text('Collection Title')
      expect(page).to have_no_text('already exists')
      fill_in 'collection_title', with: 'foo'
      expect(page).to have_text('already exists')
    end
  end
end
