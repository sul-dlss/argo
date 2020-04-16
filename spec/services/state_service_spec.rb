# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StateService do
  describe '#allows_modification?' do
    subject(:allows_modification?) { service.allows_modification? }

    before do
      allow(Dor::Workflow::Client).to receive(:new).and_return(workflow_client)
    end

    let(:pid) { 'ab12cd3456' }
    let(:workflow_client) { instance_double(Dor::Workflow::Client) }

    context 'when version is not passed in' do
      let(:item) { instance_double(Dor::Item, current_version: 4) }
      let(:service) { described_class.new(pid, version: item.current_version) }

      before do
        allow(Dor).to receive(:find).and_return(item)
      end

      context "if the object hasn't been submitted" do
        before do
          allow(workflow_client).to receive(:lifecycle).and_return(false)
        end

        it 'returns true' do
          expect(allows_modification?).to be true
          expect(workflow_client).to have_received(:lifecycle).with(druid: 'ab12cd3456', milestone_name: 'submitted')
        end
      end

      context 'if there is an open version' do
        before do
          allow(workflow_client).to receive(:lifecycle).and_return(true)
          allow(workflow_client).to receive(:active_lifecycle).and_return(true)
        end

        it 'returns true' do
          expect(allows_modification?).to be true
          expect(workflow_client).to have_received(:lifecycle).with(druid: 'ab12cd3456', milestone_name: 'submitted')
          expect(workflow_client).to have_received(:active_lifecycle).with(druid: 'ab12cd3456', milestone_name: 'opened', version: 4)
        end
      end
    end

    context 'when version is passed in' do
      let(:service) { described_class.new(pid, version: 3) }

      context "if the object hasn't been submitted" do
        before do
          allow(workflow_client).to receive(:lifecycle).and_return(false)
        end

        it 'returns true' do
          expect(allows_modification?).to be true
          expect(workflow_client).to have_received(:lifecycle).with(druid: 'ab12cd3456', milestone_name: 'submitted')
        end
      end

      context 'if there is an open version' do
        before do
          allow(workflow_client).to receive(:lifecycle).and_return(true)
          allow(workflow_client).to receive(:active_lifecycle).and_return(true)
        end

        it 'returns true' do
          expect(allows_modification?).to be true
          expect(workflow_client).to have_received(:lifecycle).with(druid: 'ab12cd3456', milestone_name: 'submitted')
          expect(workflow_client).to have_received(:active_lifecycle).with(druid: 'ab12cd3456', milestone_name: 'opened', version: 3)
        end
      end
    end
  end
end
