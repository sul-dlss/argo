# frozen_string_literal: true

require 'rails_helper'

RSpec.describe VirtualMergeJob, type: :job do
  let(:tool) { instance_double(VirtualMergeTool, run: true) }
  let(:client) do
    instance_double(Dor::Services::Client::Object, version: version_client, add_constituents: true)
  end
  let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, close: true) }
  let(:bulk_action) { create(:bulk_action) }

  describe '#perform' do
    subject(:perform) do
      described_class.perform_now(bulk_action.id,
                                  parent_druid: 'parent',
                                  child_druids: ['one', 'two'])
    end

    before do
      allow(Dor::Services::Client).to receive(:object).and_return(client)
    end

    it 'calls the dor-services-app API' do
      perform
      expect(client).to have_received(:add_constituents).with(child_druids: ['one', 'two'])
      expect(version_client).to have_received(:close).exactly(3).times
    end
  end
end
