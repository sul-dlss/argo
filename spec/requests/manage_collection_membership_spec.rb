# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Collection membership" do
  before do
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_service)
    allow(Argo::Indexer).to receive(:reindex_druid_remotely)
    allow(StateService).to receive(:new).and_return(state_service)
  end

  let(:druid) { "druid:bc123df4567" }
  let(:state_service) { instance_double(StateService, allows_modification?: true) }

  describe "adding a new collection" do
    let(:cocina_collection) { build(:dro_with_metadata, id: druid, collection_ids:) }
    let(:collection_ids) { ["druid:gg333xx4444"] }
    let(:object_service) do
      instance_double(Dor::Services::Client::Object,
        find: cocina_collection,
        update: true,
        collections: [])
    end

    context "when they have manage access" do
      before do
        sign_in create(:user), groups: ["sdr:administrator-role"]
      end

      context "when collections already exist" do
        let(:expected) do
          build(:dro_with_metadata, id: druid, collection_ids: ["druid:gg333xx4444", "druid:bc555gh3434"])
        end

        it "adds a collection" do
          post "/items/#{druid}/collection/add?collection=druid:bc555gh3434"
          expect(object_service).to have_received(:update).with(params: expected)
        end

        context "when no collection parameter is supplied" do
          it "does not add a collection" do
            post "/items/#{druid}/collection/add?collection="
            expect(object_service).not_to have_received(:update)
          end
        end
      end

      context "when the object is not currently in a collection" do
        let(:expected) { build(:dro_with_metadata, id: druid, collection_ids: ["druid:bc555gh3434"]) }
        let(:collection_ids) { [] }

        it "adds a collection" do
          post "/items/#{druid}/collection/add?collection=druid:bc555gh3434"
          expect(object_service).to have_received(:update).with(params: expected)
        end
      end
    end

    context "when they don't have manage access" do
      before do
        sign_in create(:user), groups: []
      end

      it "returns 403" do
        post "/items/#{druid}/collection/add?collection=druid:bc555gh3434"
        expect(response).to have_http_status(:forbidden)
        expect(object_service).not_to have_received(:update)
      end
    end
  end

  describe "removing a collection" do
    let(:cocina) { build(:dro_with_metadata, id: druid, collection_ids: ["druid:gg333xx4444", "druid:bc555gh3434"]) }

    let(:object_service) do
      instance_double(Dor::Services::Client::Object,
        find: cocina,
        update: true,
        collections: [])
    end

    context "when they have manage access" do
      before do
        sign_in create(:user), groups: ["sdr:administrator-role"]
      end

      context "when the item is a member of the collection" do
        let(:expected) { build(:dro_with_metadata, id: druid, collection_ids: ["druid:gg333xx4444"]) }

        it "removes a collection" do
          get "/items/#{druid}/collection/delete?collection=druid:bc555gh3434"

          expect(object_service).to have_received(:update).with(params: expected)
        end
      end

      context "when the object is not in any collections" do
        let(:cocina) { build(:dro_with_metadata, id: druid) }

        it "does an update with no changes" do
          get "/items/#{druid}/collection/delete?collection=druid:bc555gh3434"
          expect(object_service).to have_received(:update).with(params: cocina)
        end
      end
    end

    context "when they don't have manage access" do
      before do
        sign_in create(:user), groups: []
      end

      it "returns 403" do
        get "/items/#{druid}/collection/delete?collection=druid:bc555gh3434"

        expect(response).to have_http_status(:forbidden)
        expect(object_service).not_to have_received(:update)
      end
    end
  end
end
