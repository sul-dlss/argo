# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StateService do
  before do
    allow(Dor::Workflow::Client).to receive(:new).and_return(workflow_client)
    allow(workflow_client).to receive(:workflow_status).with(druid:, process: 'accessioning-initiate',
                                                             workflow: 'assemblyWF').and_return('completed')
    allow(workflow_client).to receive(:lifecycle).with(druid:, milestone_name: 'accessioned').and_return(false)
  end

  let(:druid) { 'ab12cd3456' }
  let(:workflow_client) { instance_double(Dor::Workflow::Client) }
  let(:cocina) { instance_double(Cocina::Models::DRO, externalIdentifier: druid, version: 3) }
  let(:service) { described_class.new(cocina) }

  describe '#object_state' do
    context "if the object is not opened and hasn't been submitted" do
      before do
        allow(workflow_client).to receive(:active_lifecycle).with(druid:, milestone_name: 'submitted',
                                                                  version: 3).and_return(false)
        allow(workflow_client).to receive(:active_lifecycle).with(druid:, milestone_name: 'opened',
                                                                  version: 3).and_return(false)
      end

      it 'returns unlock_inactive' do
        expect(service.object_state).to eq :unlock_inactive
      end
    end

    context "if the object is open and hasn't been submitted" do
      before do
        allow(workflow_client).to receive(:active_lifecycle).with(druid:, milestone_name: 'submitted',
                                                                  version: 3).and_return(false)
        allow(workflow_client).to receive(:active_lifecycle).with(druid:, milestone_name: 'opened',
                                                                  version: 3).and_return(true)
      end

      it 'returns unlock' do
        expect(service.object_state).to eq :unlock
      end
    end

    context 'if there is not an open version' do
      before do
        allow(workflow_client).to receive(:active_lifecycle).with(druid:, milestone_name: 'submitted',
                                                                  version: 3).and_return(true)
        allow(workflow_client).to receive(:active_lifecycle).with(druid:, milestone_name: 'opened',
                                                                  version: 3).and_return(false)
      end

      it 'returns lock_inactive' do
        expect(service.object_state).to eq :lock_inactive
      end
    end

    context 'if the object is accessioned, not submitted and not opened' do
      before do
        allow(workflow_client).to receive(:active_lifecycle).with(druid:, milestone_name: 'submitted',
                                                                  version: 3).and_return(false)
        allow(workflow_client).to receive(:active_lifecycle).with(druid:, milestone_name: 'opened',
                                                                  version: 3).and_return(false)
        allow(workflow_client).to receive(:lifecycle).with(druid:, milestone_name: 'accessioned').and_return(true)
      end

      it 'returns lock' do
        expect(service.object_state).to eq :lock
      end
    end
  end
end
