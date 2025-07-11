# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MilestoneService do
  let(:fake_milestones_client) { instance_double(Dor::Services::Client::Milestones, list: milestones_payload) }
  let(:fake_object_client) { instance_double(Dor::Services::Client::Object, milestones: fake_milestones_client) }
  let(:milestones) { described_class.milestones_for(druid: 'druid:bc123cd4567') }

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(fake_object_client)
  end

  describe '.milestones_for' do
    context 'when service returns an array of milestones' do
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

      it 'returns a formatted list of milestones by version' do
        expect(milestones).to eq({
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
        })
        expect(fake_object_client).to have_received(:milestones).once
        expect(fake_milestones_client).to have_received(:list).once
      end
    end

    context 'when service returns an empty array' do
      let(:milestones_payload) { [] }

      it 'returns a formatted list of milestones by version' do
        expect(milestones).to eq({})
        expect(fake_object_client).to have_received(:milestones).once
        expect(fake_milestones_client).to have_received(:list).once
      end
    end
  end
end
