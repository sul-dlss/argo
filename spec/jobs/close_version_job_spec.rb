# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CloseVersionJob, type: :job do
  let(:pids) { ['druid:123', 'druid:456'] }
  let(:groups) { [] }
  let(:user) { instance_double(User, to_s: 'jcoyne85') }
  let(:client) { instance_double(Dor::Services::Client::Object, version: version_client) }
  let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, close: true) }
  let(:bulk_action) do
    create(:bulk_action,
           log_name: 'foo.txt')
  end
  let(:item1) { Dor::Item.new }
  let(:item2) { Dor::Item.new }

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(client)
    allow(Ability).to receive(:new).and_return(ability)
    allow(Dor).to receive(:find).with(pids[0]).and_return(item1)
    allow(Dor).to receive(:find).with(pids[1]).and_return(item2)
  end

  after do
    FileUtils.rm('foo.txt')
  end

  context 'with manage ability' do
    let(:ability) { instance_double(Ability, can?: true) }

    it 'closes versions' do
      described_class.perform_now(bulk_action.id,
                                  pids: pids,
                                  groups: groups,
                                  user: user)

      expect(version_client).to have_received(:close).twice
    end
  end

  context 'without manage ability' do
    let(:ability) { instance_double(Ability, can?: false) }

    it 'does not close versions' do
      described_class.perform_now(bulk_action.id,
                                  pids: pids,
                                  groups: groups,
                                  user: user)

      expect(version_client).not_to have_received(:close)
    end
  end
end
