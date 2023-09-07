# frozen_string_literal: true

require "rails_helper"

RSpec.describe StateService do
  before do
    allow(Dor::Workflow::Client).to receive(:new).and_return(workflow_client)
    allow(workflow_client).to receive(:workflow_status).with(druid:, process: "accessioning-initiate", workflow: "assemblyWF").and_return("completed")
    allow(workflow_client).to receive(:lifecycle).with(druid:, milestone_name: "accessioned").and_return(false)
  end

  let(:druid) { "ab12cd3456" }
  let(:workflow_client) { instance_double(Dor::Workflow::Client) }
  let(:cocina) { instance_double(Cocina::Models::DRO, externalIdentifier: druid, version: 3) }
  let(:service) { described_class.new(cocina) }

  describe "#allows_modification?" do
    before do
      allow(service).to receive(:object_state).and_return(:unlock)
    end

    context "if the object state is unlock" do
      before do
        allow(service).to receive(:object_state).and_return(:unlock)
      end

      it "returns true" do
        expect(service).to be_allows_modification
      end
    end

    context "if the object state is unlock_inactive" do
      before do
        allow(service).to receive(:object_state).and_return(:unlock_inactive)
      end

      it "returns true" do
        expect(service).to be_allows_modification
      end
    end

    context "if the object state is lock" do
      before do
        allow(service).to receive(:object_state).and_return(:lock)
      end

      it "returns false" do
        expect(service).not_to be_allows_modification
      end
    end

    context "if the object state is lock_inactive" do
      before do
        allow(service).to receive(:object_state).and_return(:lock_inactive)
      end

      it "returns false" do
        expect(service).not_to be_allows_modification
      end
    end
  end

  describe "#object_state" do
    context "if the object is not opened and hasn't been submitted" do
      before do
        allow(workflow_client).to receive(:active_lifecycle).with(druid:, milestone_name: "submitted", version: 3).and_return(false)
        allow(workflow_client).to receive(:active_lifecycle).with(druid:, milestone_name: "opened", version: 3).and_return(false)
      end

      it "returns unlock_inactive" do
        expect(service.object_state).to eq :unlock_inactive
      end
    end

    context "if the object is open and hasn't been submitted" do
      before do
        allow(workflow_client).to receive(:active_lifecycle).with(druid:, milestone_name: "submitted", version: 3).and_return(false)
        allow(workflow_client).to receive(:active_lifecycle).with(druid:, milestone_name: "opened", version: 3).and_return(true)
      end

      it "returns unlock" do
        expect(service.object_state).to eq :unlock
      end
    end

    context "if there is not an open version" do
      before do
        allow(workflow_client).to receive(:active_lifecycle).with(druid:, milestone_name: "submitted", version: 3).and_return(true)
        allow(workflow_client).to receive(:active_lifecycle).with(druid:, milestone_name: "opened", version: 3).and_return(false)
      end

      it "returns lock_inactive" do
        expect(service.object_state).to eq :lock_inactive
      end
    end

    context "if the object is accessioned, not submitted and not opened" do
      before do
        allow(workflow_client).to receive(:active_lifecycle).with(druid:, milestone_name: "submitted", version: 3).and_return(false)
        allow(workflow_client).to receive(:active_lifecycle).with(druid:, milestone_name: "opened", version: 3).and_return(false)
        allow(workflow_client).to receive(:lifecycle).with(druid:, milestone_name: "accessioned").and_return(true)
      end

      it "returns lock" do
        expect(service.object_state).to eq :lock
      end
    end
  end

  describe "#published?" do
    before do
      allow(workflow_client).to receive(:workflow_status).with(druid:, process: "accessioning-initiate", workflow: "assemblyWF").and_return("completed")
      allow(workflow_client).to receive(:lifecycle).with(druid:, milestone_name: "accessioned").and_return(false)
    end

    context "if the published lifecycle exists" do
      before do
        allow(workflow_client).to receive(:lifecycle).with(druid:, milestone_name: "published").and_return(true)
      end

      it "returns true" do
        expect(service).to be_published
      end
    end

    context "if the published lifecycle does not exist" do
      before do
        allow(workflow_client).to receive(:lifecycle).with(druid:, milestone_name: "published").and_return(false)
      end

      it "returns false" do
        expect(service).not_to be_published
      end
    end
  end

  describe "#accessioned?" do
    context "if the accessioned lifecycle exists" do
      before do
        allow(workflow_client).to receive(:lifecycle).with(druid:, milestone_name: "accessioned").and_return("2022-04-20 21:55:25 +0000")
      end

      it "returns true" do
        expect(service).to be_accessioned
      end
    end

    context "if the accessioned lifecycle does not exist" do
      before do
        allow(workflow_client).to receive(:lifecycle).with(druid:, milestone_name: "accessioned").and_return(nil)
      end

      it "returns false" do
        expect(service).not_to be_accessioned
      end
    end
  end
end
