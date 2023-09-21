# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Add collection" do
  before do
    allow(Blacklight::Solr::Repository).to receive(:new).and_return(repo)
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    sign_in create(:user), groups: ["sdr:administrator-role"]
  end

  let(:repo) { instance_double(Blacklight::Solr::Repository, connection: solr_client) }
  let(:solr_client) { instance_double(RSolr::Client, get: result) }
  let(:result) { {"response" => {"numFound" => 1}} }
  let(:apo_id) { "druid:vt333hq2222" }
  let(:cocina_model) { instance_double(Cocina::Models::AdminPolicyWithMetadata, label: "hey", externalIdentifier: apo_id) }
  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model) }

  describe "during folio cutover when collection catalog_record_id is provided", :js do
    before do
      allow(Settings).to receive(:ils_cutover_in_progress).and_return(true)
    end

    it "doesn't allow the collection to be created" do
      visit new_apo_collection_path apo_id
      expect(page).not_to have_text("Create a Collection from Folio")
    end
  end

  describe "when collection catalog_record_id is provided", :js do
    it "warns if catalog_record_id exists" do
      visit new_apo_collection_path apo_id
      choose "Create a Collection from #{CatalogRecordId.type.capitalize}"
      expect(page).to have_text("Collection #{CatalogRecordId.label}")
      expect(page).not_to have_text("already exists")
      fill_in "collection_catalog_record_id", with: "foo"
      expect(page).to have_text("already exists")
    end
  end

  describe "when collection title is provided", :js do
    it "warns if title exists" do
      visit new_apo_collection_path apo_id
      expect(page).to have_text("Collection Title")
      expect(page).not_to have_text("already exists")
      fill_in "collection_title", with: "foo"
      expect(page).to have_text("already exists")
    end
  end
end
