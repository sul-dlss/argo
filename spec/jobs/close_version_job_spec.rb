# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CloseVersionJob, type: :job do
  let(:druids) { ['druid:bc123df4567', 'druid:bc123df4598'] }
  let(:groups) { [] }
  let(:user) { instance_double(User, to_s: 'jcoyne85') }
  let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, close: true) }
  let(:bulk_action) { create(:bulk_action) }

  let(:item1) do
    build(:dro_with_metadata, id: druids[0])
  end
  let(:item2) do
    build(:dro_with_metadata, id: druids[1])
  end
  let(:object_client1) { instance_double(Dor::Services::Client::Object, find: item1, version: version_client) }
  let(:object_client2) { instance_double(Dor::Services::Client::Object, find: item2, version: version_client) }

  before do
    allow(Ability).to receive(:new).and_return(ability)
    allow(Dor::Services::Client).to receive(:object).with(druids[0]).and_return(object_client1)
    allow(Dor::Services::Client).to receive(:object).with(druids[1]).and_return(object_client2)
  end

  after do
    FileUtils.rm(bulk_action.log_name)
  end

  context 'with manage ability' do
    let(:ability) { instance_double(Ability, can?: true) }

    it 'closes versions' do
      described_class.perform_now(bulk_action.id,
                                  druids:,
                                  groups:,
                                  user:)

      expect(version_client).to have_received(:close).twice
    end
  end

  context 'without manage ability' do
    let(:ability) { instance_double(Ability, can?: false) }

    it 'does not close versions' do
      described_class.perform_now(bulk_action.id,
                                  druids:,
                                  groups:,
                                  user:)

      expect(version_client).not_to have_received(:close)
    end
  end
end
