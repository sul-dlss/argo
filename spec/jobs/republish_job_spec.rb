# frozen_string_literal: true

require "rails_helper"

RSpec.describe RepublishJob, type: :job do
  let(:druids) { ["druid:123", "druid:456"] }
  let(:groups) { [] }
  let(:user) { instance_double(User, to_s: "jcoyne85") }
  let(:bulk_action) { create(:bulk_action) }

  let(:client1) { instance_double(Dor::Services::Client::Object, publish: true) }
  let(:client2) { instance_double(Dor::Services::Client::Object, publish: true) }

  before do
    allow(Dor::Services::Client).to receive(:object).with(druids[0]).and_return(client1)
    allow(Dor::Services::Client).to receive(:object).with(druids[1]).and_return(client2)
    allow(Dor::Workflow::Client).to receive(:new).and_return(client)

    described_class.perform_now(bulk_action.id,
      druids:,
      groups:,
      user:)
  end

  after do
    FileUtils.rm(bulk_action.log_name)
  end

  context "with already published objects" do
    let(:client) { instance_double(Dor::Workflow::Client, lifecycle: Time.zone.now) }

    it "publishes objects" do
      expect(client1).to have_received(:publish)
      expect(client2).to have_received(:publish)
    end
  end

  context "when objects have never been published" do
    let(:client) { instance_double(Dor::Workflow::Client, lifecycle: nil) }

    it "does not publish objects" do
      expect(client1).not_to have_received(:publish)
      expect(client2).not_to have_received(:publish)
    end
  end
end
