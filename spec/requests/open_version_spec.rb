# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Open a version" do
  let(:druid) { "druid:bc123df4567" }
  let(:user) { create(:user) }
  let(:object_service) { instance_double(Dor::Services::Client::Object, find: cocina_model) }
  let(:cocina_model) { build(:dro_with_metadata, id: druid) }

  before do
    allow(Argo::Indexer).to receive(:reindex_druid_remotely)
    allow(Dor::Services::Client).to receive(:object).and_return(object_service)
  end

  context "when they have update access" do
    before do
      sign_in user, groups: ["sdr:administrator-role"]
    end

    let(:object_service) { instance_double(Dor::Services::Client::Object, version: version_client, find: cocina_model) }
    let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, open: true) }

    it "calls dor-services to open a new version" do
      expect(Argo::Indexer).to receive(:reindex_druid_remotely)

      post "/items/#{druid}/versions/open", params: {significance: "major", description: "something"}

      expect(version_client).to have_received(:open).with(significance: "major", description: "something", opening_user_name: user.to_s)
    end
  end

  context "without manage item access" do
    before do
      sign_in user
    end

    it "returns a 403" do
      post "/items/#{druid}/versions/open", params: {significance: "major", description: "something"}

      expect(response).to have_http_status(:forbidden)
    end
  end
end
