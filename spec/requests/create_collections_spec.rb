# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Create collections" do
  before do
    sign_in user, groups: ["sdr:administrator-role"]
  end

  let(:apo_id) { "druid:zt570qh4444" }
  let(:collection_id) { "druid:bp475vb4486" }
  let(:user) { create(:user) }
  let(:collection) { instance_double(Cocina::Models::Collection, externalIdentifier: collection_id) }

  describe "show the form" do
    let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model) }
    let(:cocina_model) do
      build(:admin_policy_with_metadata)
    end

    before do
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    end

    it "is successful" do
      get "/apo/#{apo_id}/collections/new"
      expect(response).to be_successful
    end
  end

  describe "save the form" do
    let(:form) { instance_double(CollectionForm, validate: true, save: true, model: collection) }
    let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model, update: true) }
    let(:cocina_model) do
      build(:admin_policy_with_metadata)
    end

    before do
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
      allow(CollectionForm).to receive(:new).and_return(form)
      allow(Argo::Indexer).to receive(:reindex_druid_remotely)
    end

    it "creates a collection using the form" do
      post "/apo/#{apo_id}/collections", params: {"label" => ":auto",
                                                  "collection_catkey" => "1234567",
                                                  "collection_rights_catkey" => "dark"}
      expect(response).to be_redirect # redirects to catalog page
      expect(form).to have_received(:save)
      expect(object_client).to have_received(:update).with(params: cocina_admin_policy_with_registration_collections([collection_id]))
      expect(Argo::Indexer).to have_received(:reindex_druid_remotely).with(apo_id)
    end
  end

  describe "check that it's not a duplicate" do
    let(:title) { "foo" }
    let(:catkey) { "123" }
    let(:repo) { instance_double(Blacklight::Solr::Repository, connection: solr_client) }
    let(:solr_client) { instance_double(RSolr::Client, get: result) }

    before do
      allow(Blacklight::Solr::Repository).to receive(:new).and_return(repo)
    end

    context "when the title is provided and the collection exists" do
      let(:result) { {"response" => {"numFound" => 1}} }

      it "returns true" do
        get "/collections/exists?title=#{title}"
        expect(response.body).to eq("true")
        expect(solr_client).to have_received(:get).with("select", params: a_hash_including(
          q: '_query_:"{!raw f=objectType_ssim}collection" AND obj_label_tesim:"foo"'
        ))
      end
    end

    context "when the title is provided and the collection does not exist" do
      let(:result) { {"response" => {"numFound" => 0}} }

      it "returns false" do
        get "/collections/exists?title=#{title}"
        expect(response.body).to eq("false")
      end
    end

    context "when the catkey is provided and the collection exists" do
      let(:result) { {"response" => {"numFound" => 1}} }

      it "returns true" do
        get "/collections/exists?catkey=#{catkey}"
        expect(response.body).to eq("true")
        expect(solr_client).to have_received(:get).with("select", params: a_hash_including(
          q: '_query_:"{!raw f=objectType_ssim}collection" AND identifier_ssim:"catkey:123"'
        ))
      end
    end

    context "when the catkey is provided and the collection does not exist" do
      let(:result) { {"response" => {"numFound" => 0}} }

      it "returns false" do
        get "/collections/exists?catkey=#{catkey}"
        expect(response.body).to eq("false")
      end
    end

    context "when the title and catkey is provided and the collection exists" do
      let(:result) { {"response" => {"numFound" => 1}} }

      it "returns true if collection with title and catkey exists" do
        get "/collections/exists?catkey=#{catkey}&title=#{title}"
        expect(response.body).to eq("true")
        expect(solr_client).to have_received(:get).with("select", params: a_hash_including(
          q: '_query_:"{!raw f=objectType_ssim}collection" AND obj_label_tesim:"foo" AND identifier_ssim:"catkey:123"'
        ))
      end
    end
  end
end
