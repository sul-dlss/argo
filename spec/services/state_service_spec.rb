# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StateService do
  describe '#allows_modification?' do
    subject(:allows_modification?) { service.allows_modification? }

    before do
      allow(Dor::Workflow::Client).to receive(:new).and_return(workflow_client)
      allow(workflow_client).to receive(:workflow_status).with(druid: pid, process: 'accessioning-initiate', workflow: 'assemblyWF').and_return(false)
      allow(workflow_client).to receive(:lifecycle).with(druid: pid, milestone_name: 'accessioned').and_return(false)
    end

    let(:pid) { 'ab12cd3456' }
    let(:workflow_client) { instance_double(Dor::Workflow::Client) }

    context 'when version is not passed in' do
      let(:service) { described_class.new(pid, version: 4) }

      context "if the object hasn't been submitted" do
        before do
          allow(workflow_client).to receive(:active_lifecycle).with(druid: pid, milestone_name: 'submitted', version: 4).and_return(false)
          allow(workflow_client).to receive(:active_lifecycle).with(druid: pid, milestone_name: 'opened', version: 4).and_return(false)
        end

        it 'returns true' do
          expect(allows_modification?).to be true
          expect(workflow_client).to have_received(:active_lifecycle).with(druid: 'ab12cd3456', milestone_name: 'submitted', version: 4)
          expect(workflow_client).to have_received(:active_lifecycle).with(druid: 'ab12cd3456', milestone_name: 'opened', version: 4).twice
        end
      end

      context 'if there is an open version' do
        before do
          allow(workflow_client).to receive(:active_lifecycle).with(druid: pid, milestone_name: 'submitted', version: 4).and_return(false)
          allow(workflow_client).to receive(:active_lifecycle).with(druid: pid, milestone_name: 'opened', version: 4).and_return(true)
        end

        it 'returns true' do
          expect(allows_modification?).to be true
          expect(workflow_client).to have_received(:active_lifecycle).with(druid: 'ab12cd3456', milestone_name: 'submitted', version: 4)
          expect(workflow_client).to have_received(:active_lifecycle).with(druid: 'ab12cd3456', milestone_name: 'opened', version: 4)
        end
      end
    end

    context 'when version is passed in' do
      let(:service) { described_class.new(pid, version: 3) }

      context "if the object hasn't been submitted" do
        before do
          allow(workflow_client).to receive(:active_lifecycle).with(druid: pid, milestone_name: 'submitted', version: 3).and_return(false)
          allow(workflow_client).to receive(:active_lifecycle).with(druid: pid, milestone_name: 'opened', version: 3).and_return(false)
        end

        it 'returns true' do
          expect(allows_modification?).to be true
          expect(workflow_client).to have_received(:active_lifecycle).with(druid: 'ab12cd3456', milestone_name: 'submitted', version: 3)
          expect(workflow_client).to have_received(:active_lifecycle).with(druid: 'ab12cd3456', milestone_name: 'opened', version: 3).twice
        end
      end

      context 'if there is an open version' do
        before do
          allow(workflow_client).to receive(:active_lifecycle).with(druid: pid, milestone_name: 'submitted', version: 3).and_return(false)
          allow(workflow_client).to receive(:active_lifecycle).with(druid: pid, milestone_name: 'opened', version: 3).and_return(true)
        end

        it 'returns true' do
          expect(allows_modification?).to be true
          expect(workflow_client).to have_received(:active_lifecycle).with(druid: 'ab12cd3456', milestone_name: 'submitted', version: 3)
          expect(workflow_client).to have_received(:active_lifecycle).with(druid: 'ab12cd3456', milestone_name: 'opened', version: 3)
        end
      end
    end
  end
end
