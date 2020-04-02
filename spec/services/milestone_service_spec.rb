# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MilestoneService do
  let(:druid1) { 'druid:br481xz7820' }
  let(:druid2) { 'druid:ab123cd4567' }
  let(:args) do
    {
      druid: druid
    }
  end

  let(:milestones_payload) do
    [
      { milestone: 'submitted', at: '2020-03-30 20:23:35 +0000', version: '1' },
      { milestone: 'described', at: '2020-03-30 20:57:36 +0000', version: '1' },
      { milestone: 'published', at: '2020-03-30 21:01:20 +0000', version: '1' },
      { milestone: 'deposited', at: '2020-03-30 21:01:51 +0000', version: '1' },
      { milestone: 'accessioned', at: '2020-03-30 21:02:03 +0000', version: '1' },
      { milestone: 'submitted', at: '2020-03-31 20:23:35 +0000', version: '2' },
      { milestone: 'described', at: '2020-03-31 20:57:36 +0000', version: '2' },
      { milestone: 'published', at: '2020-03-31 21:01:20 +0000', version: '2' },
      { milestone: 'deposited', at: '2020-03-31 21:01:51 +0000', version: '2' },
      { milestone: 'accessioned', at: '2020-03-31 21:02:03 +0000', version: '2' }
    ]
  end

  let(:formatted_milestones) do
    {
      '1' => {
        'registered' => {},
        'submitted' => { time: '2020-03-30 20:23:35 +0000' },
        'described' => { time: '2020-03-30 20:57:36 +0000' },
        'published' => { time: '2020-03-30 21:01:20 +0000' },
        'deposited' => { time: '2020-03-30 21:01:51 +0000' },
        'accessioned' => { time: '2020-03-30 21:02:03 +0000' }
      },
      '2' => {
        'submitted' => { time: '2020-03-31 20:23:35 +0000' },
        'described' => { time: '2020-03-31 20:57:36 +0000' },
        'opened' => {},
        'published' => { time: '2020-03-31 21:01:20 +0000' },
        'deposited' => { time: '2020-03-31 21:01:51 +0000' },
        'accessioned' => { time: '2020-03-31 21:02:03 +0000' }
      }
    }
  end

  describe '.milestones_for' do
    before do
      allow(WorkflowClientFactory).to receive(:build).and_return(fake_workflow_client)
    end

    context 'when service returns an array of milestones' do
      let(:milestones) { described_class.milestones_for(druid: druid1) }
      let(:fake_workflow_client) { instance_double(Dor::Workflow::Client, milestones: milestones_payload) }

      it 'returns a formatted list of milestones by version' do
        expect(milestones).to eq(formatted_milestones)
        expect(fake_workflow_client).to have_received(:milestones).once
      end
    end

    context 'when service returns an empty array' do
      let(:milestones) { described_class.milestones_for(druid: druid2) }
      let(:fake_workflow_client) { instance_double(Dor::Workflow::Client, milestones: []) }

      it 'returns a formatted list of milestones by version' do
        expect(milestones).to eq({})
        expect(fake_workflow_client).to have_received(:milestones).once
      end
    end
  end
end
