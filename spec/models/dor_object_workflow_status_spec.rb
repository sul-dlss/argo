# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DorObjectWorkflowStatus do
  subject { described_class.new(pid, version: 1) }

  let(:pid) { 'druid:abc123def4567' }

  describe '#can_open_version?' do
    let(:workflow_client) { instance_double(Dor::Workflow::Client, lifecycle: true, active_lifecycle: true) }

    before do
      allow(Dor::Workflow::Client).to receive(:new).and_return(workflow_client)
    end

    context 'when not accessioned' do
      before do
        expect(workflow_client)
          .to receive(:lifecycle).with(druid: pid, milestone_name: 'accessioned')
                                 .and_return(false)
      end

      it { expect(subject.can_open_version?).to eq false }
    end

    context 'when accessioned and submitted' do
      before do
        expect(workflow_client).to receive(:lifecycle)
          .with(druid: pid, milestone_name: 'accessioned').and_return(true)
        expect(workflow_client).to receive(:active_lifecycle)
          .with(druid: pid, milestone_name: 'submitted', version: 1).and_return(true)
      end

      it { expect(subject.can_open_version?).to eq false }
    end

    context 'when accessioned, not submitted, and opened' do
      before do
        expect(workflow_client)
          .to receive(:lifecycle).with(druid: pid, milestone_name: 'accessioned')
                                 .and_return(true)
        expect(workflow_client)
          .to receive(:active_lifecycle).with(druid: pid, milestone_name: 'submitted', version: 1)
                                        .and_return(false)
        expect(workflow_client)
          .to receive(:active_lifecycle).with(druid: pid, milestone_name: 'opened', version: 1)
                                        .and_return(true)
      end

      it { expect(subject.can_open_version?).to eq false }
    end

    context 'when accessioned, not submitted, and not opened' do
      before do
        expect(workflow_client)
          .to receive(:lifecycle).with(druid: pid, milestone_name: 'accessioned')
                                 .and_return(true)
        expect(workflow_client)
          .to receive(:active_lifecycle).with(druid: pid, milestone_name: 'submitted', version: 1)
                                        .and_return(false)
        expect(workflow_client)
          .to receive(:active_lifecycle).with(druid: pid, milestone_name: 'opened', version: 1)
                                        .and_return(false)
      end

      it { expect(subject.can_open_version?).to eq true }
    end
  end
end
