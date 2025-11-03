# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Add collection' do
  before do
    allow(Blacklight::Solr::Repository).to receive(:new).and_return(repo)
    allow(AdminPolicyOptions).to receive(:for).and_return([['An APO', 'druid:vt333hq2222']])
    allow(FolioClient).to receive(:fetch_marc_hash).with(instance_hrid: 'a123')

    sign_in create(:user), groups: ['sdr:administrator-role']
  end

  let(:repo) { instance_double(Blacklight::Solr::Repository, connection: solr_client) }
  let(:solr_client) { instance_double(RSolr::Client, get: result) }
  let(:result) { { 'response' => { 'numFound' => 1 } } }

  describe 'when collection catalog_record_id is provided', :js do
    it 'warns if catalog_record_id exists' do
      visit new_collection_path

      choose "Create a Collection from #{CatalogRecordId.type.capitalize}"
      expect(page).to have_text("Collection #{CatalogRecordId.label}")
      expect(page).to have_no_text('already exists')
      fill_in 'collection_catalog_record_id', with: 'a123'
      expect(page).to have_text('already exists')
    end
  end

  describe 'when invalid FOLIO Collection HRID is provided', :js do
    let(:result) { { 'response' => { 'numFound' => 0 } } }

    it 'warns that catalog id is not formatted correctly' do
      visit new_collection_path

      choose "Create a Collection from #{CatalogRecordId.type.capitalize}"
      expect(page).to have_text("Collection #{CatalogRecordId.label}")
      fill_in 'collection_catalog_record_id', with: '123'
      expect(page).to have_text('Collection Folio Instance HRID must be in an allowed format.')
      fill_in 'collection_catalog_record_id', with: 'a123'
      expect(page).to have_no_text('Collection Folio Instance HRID must be in an allowed format.')
    end
  end

  describe 'when non-existent FOLIO Collection HRID is provided', :js do
    before do
      allow(FolioClient).to receive(:fetch_marc_hash).with(instance_hrid: 'a1234').and_raise(FolioClient::ResourceNotFound)
    end

    it 'warns that catalog id does not exist' do
      visit new_collection_path

      choose "Create a Collection from #{CatalogRecordId.type.capitalize}"
      expect(page).to have_text("Collection #{CatalogRecordId.label}")
      fill_in 'collection_catalog_record_id', with: 'a1234'
      expect(page).to have_text('does not exist')
      fill_in 'collection_catalog_record_id', with: 'a123'
      expect(page).to have_no_text('does not exist')
    end
  end

  describe 'when collection title is provided', :js do
    it 'warns if title exists' do
      visit new_collection_path

      expect(page).to have_text('Collection Title')
      expect(page).to have_no_text('already exists')
      fill_in 'collection_title', with: 'foo'
      expect(page).to have_text('already exists')
    end
  end
end
