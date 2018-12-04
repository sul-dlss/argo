# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DorObjectWorkflowStatus do
  subject { described_class.new(pid) }
  let(:pid) { 'druid:abc123def4567' }
  describe '#can_open_version?' do
    context 'when not accessioned' do
      before do
        expect(Dor::Config.workflow.client)
          .to receive(:get_lifecycle).with('dor', pid, 'accessioned')
                                     .and_return(false)
      end
      it { expect(subject.can_open_version?).to eq false }
    end
    context 'when accessioned and submitted' do
      before do
        expect(Dor::Config.workflow.client)
          .to receive(:get_lifecycle).with('dor', pid, 'accessioned')
                                     .and_return(true)
        expect(Dor::Config.workflow.client)
          .to receive(:get_active_lifecycle).with('dor', pid, 'submitted')
                                            .and_return(true)
      end
      it { expect(subject.can_open_version?).to eq false }
    end
    context 'when accessioned, not submitted, and opened' do
      before do
        expect(Dor::Config.workflow.client)
          .to receive(:get_lifecycle).with('dor', pid, 'accessioned')
                                     .and_return(true)
        expect(Dor::Config.workflow.client)
          .to receive(:get_active_lifecycle).with('dor', pid, 'submitted')
                                            .and_return(false)
        expect(Dor::Config.workflow.client)
          .to receive(:get_active_lifecycle).with('dor', pid, 'opened')
                                            .and_return(true)
      end
      it { expect(subject.can_open_version?).to eq false }
    end
    context 'when accessioned, not submitted, and not opened' do
      before do
        expect(Dor::Config.workflow.client)
          .to receive(:get_lifecycle).with('dor', pid, 'accessioned')
                                     .and_return(true)
        expect(Dor::Config.workflow.client)
          .to receive(:get_active_lifecycle).with('dor', pid, 'submitted')
                                            .and_return(false)
        expect(Dor::Config.workflow.client)
          .to receive(:get_active_lifecycle).with('dor', pid, 'opened')
                                            .and_return(false)
      end
      it { expect(subject.can_open_version?).to eq true }
    end
  end
end
