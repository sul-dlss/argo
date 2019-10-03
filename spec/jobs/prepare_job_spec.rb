# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PrepareJob, type: :job do
  let(:pids) { ['druid:123', 'druid:456'] }
  let(:groups) { [] }
  let(:workflow_status) { instance_double(DorObjectWorkflowStatus, can_open_version?: true) }
  let(:bulk_action) do
    create(:bulk_action,
           log_name: 'foo.txt')
  end
  let(:user) { bulk_action.user }
  let(:item1) { Dor::Item.new }
  let(:item2) { Dor::Item.new }

  before do
    allow(Ability).to receive(:new).and_return(ability)
    allow(VersionService).to receive(:open)
    allow(DorObjectWorkflowStatus).to receive(:new).and_return(workflow_status)
    allow(Dor).to receive(:find).with(pids[0]).and_return(item1)
    allow(Dor).to receive(:find).with(pids[1]).and_return(item2)
  end

  after do
    FileUtils.rm('foo.txt')
  end

  context 'with manage ability' do
    let(:ability) { instance_double(Ability, can?: true) }

    it 'opens new versions' do
      described_class.perform_now(bulk_action.id,
                                  pids: pids,
                                  groups: groups,
                                  user: user,
                                  prepare: {
                                    'description' => 'Changed dates',
                                    'significance' => 'major'
                                  })

      expect(VersionService).to have_received(:open).with(identifier: anything,
                                                          description: 'Changed dates',
                                                          opening_user_name: user.to_s,
                                                          significance: 'major').twice
    end
  end

  context 'without manage ability' do
    let(:ability) { instance_double(Ability, can?: false) }

    it 'does not open new versions' do
      described_class.perform_now(bulk_action.id,
                                  pids: pids,
                                  groups: groups,
                                  user: user,
                                  prepare: {
                                    'description' => 'Changed dates',
                                    'significance' => 'major'
                                  })

      expect(VersionService).not_to have_received(:open)
    end
  end
end
