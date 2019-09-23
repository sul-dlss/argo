# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StateService do
  describe '#allows_modification?' do
    subject(:allows_modification?) { service.allows_modification? }

    let(:pid) { 'ab12cd3456' }

    let(:service) { described_class.new(pid, version: 3) }

    context "if the object hasn't been submitted" do
      before do
        allow(Dor::Config.workflow.client).to receive(:lifecycle).and_return(false)
      end

      it 'returns true' do
        expect(allows_modification?).to be true
        expect(Dor::Config.workflow.client).to have_received(:lifecycle).with('dor', 'ab12cd3456', 'submitted')
      end
    end

    context 'if there is an open version' do
      before do
        allow(Dor::Config.workflow.client).to receive(:lifecycle).and_return(true)
        allow(Dor::Config.workflow.client).to receive(:active_lifecycle).and_return(true)
      end

      it 'returns true' do
        expect(allows_modification?).to be true
        expect(Dor::Config.workflow.client).to have_received(:lifecycle).with('dor', 'ab12cd3456', 'submitted')
        expect(Dor::Config.workflow.client).to have_received(:active_lifecycle).with('dor', 'ab12cd3456', 'opened', version: 3)
      end
    end

    context 'when the item has sdr-ingest-transfer set to hold' do
      before do
        allow(Dor::Config.workflow.client).to receive(:lifecycle).and_return(true)
        allow(Dor::Config.workflow.client).to receive(:active_lifecycle).and_return(false)
        allow(Dor::Config.workflow.client).to receive(:workflow_status).and_return('hold')
      end

      it 'returns true' do
        expect(allows_modification?).to be true
        expect(Dor::Config.workflow.client).to have_received(:lifecycle).with('dor', 'ab12cd3456', 'submitted')
        expect(Dor::Config.workflow.client).to have_received(:active_lifecycle).with('dor', 'ab12cd3456', 'opened', version: 3)
      end
    end
  end
end
