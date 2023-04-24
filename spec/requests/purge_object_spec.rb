# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Purge object" do
  let(:druid) { "druid:bc123df4567" }
  let(:object_service) { instance_double(Dor::Services::Client::Object, find: cocina_model) }
  let(:cocina_model) { build(:dro_with_metadata, id: druid) }

  before do
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_service)
  end

  context "when they don't have manage access" do
    before do
      sign_in create(:user), groups: []
    end

    it "returns 403" do
      delete "/items/#{druid}/purge"
      expect(response).to have_http_status(:forbidden)
    end
  end

  context "when they have manage access" do
    let(:client) do
      instance_double(Dor::Workflow::Client,
        delete_all_workflows: nil,
        lifecycle: false)
    end

    before do
      allow(Dor::Workflow::Client).to receive(:new).and_return(client)
      sign_in create(:user), groups: ["sdr:administrator-role"]
    end

    context "when the object has not been submitted" do
      before do
        allow(WorkflowService).to receive(:submitted?).with(druid:).and_return(false)
        allow(PurgeService).to receive(:purge)
      end

      it "deletes the object" do
        delete "/items/#{druid}/purge"

        expect(response).to redirect_to root_path
        expect(flash[:notice]).to eq "#{druid} has been purged!"
        expect(PurgeService).to have_received(:purge)
      end
    end

    context "when the object has been submitted" do
      before do
        allow(WorkflowService).to receive(:submitted?).with(druid:).and_return(true)
      end

      it "blocks purge" do
        delete "/items/#{druid}/purge"

        expect(response).to have_http_status(:bad_request)
        expect(response.body).to eq("Cannot purge an object after it is submitted.")
      end
    end
  end
end
