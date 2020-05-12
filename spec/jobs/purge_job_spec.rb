# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PurgeJob, type: :job do
  let(:pids) { ['druid:123', 'druid:456'] }
  let(:groups) { [] }
  let(:user) { instance_double(User, to_s: 'jcoyne85') }
  let(:client) { instance_double(Dor::Workflow::Client, lifecycle: submitted, delete_all_workflows: true) }
  let(:submitted) { false }
  let(:bulk_action) do
    create(:bulk_action,
           log_name: 'foo.txt')
  end
  let(:item1) { instance_double(Dor::Item, delete: true) }
  let(:item2) { instance_double(Dor::Item, delete: true) }

  before do
    allow(WorkflowClientFactory).to receive(:build).and_return(client)
    allow(Ability).to receive(:new).and_return(ability)
    allow(Dor).to receive(:find).with(pids[0]).and_return(item1)
    allow(Dor).to receive(:find).with(pids[1]).and_return(item2)

    described_class.perform_now(bulk_action.id,
                                pids: pids,
                                groups: groups,
                                user: user)
  end

  after do
    FileUtils.rm('foo.txt')
  end

  context 'with manage ability' do
    let(:ability) { instance_double(Ability, can?: true) }

    context 'when submitted' do
      let(:submitted) { true }

      it "doesn't purge" do
        expect(item1).not_to have_received(:delete)
        expect(item2).not_to have_received(:delete)
      end
    end

    context 'when not submitted' do
      let(:submitted) { false }

      it 'purges objects' do
        expect(item1).to have_received(:delete)
        expect(item2).to have_received(:delete)
        expect(client).to have_received(:delete_all_workflows).twice
      end
    end
  end

  context 'without manage ability' do
    let(:ability) { instance_double(Ability, can?: false) }

    it "doesn't purge" do
      expect(item1).not_to have_received(:delete)
      expect(item2).not_to have_received(:delete)
    end
  end
end
