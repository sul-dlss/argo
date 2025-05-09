# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OpenVersionJob do
  let(:druids) { ['druid:bb111cc2222', 'druid:cc111dd2222'] }
  let(:groups) { [] }
  let(:bulk_action) { create(:bulk_action) }
  let(:user) { bulk_action.user }

  let(:cocina1) do
    build(:dro_with_metadata, id: druids[0])
  end
  let(:cocina2) do
    build(:dro_with_metadata, id: druids[1])
  end

  let(:object_client1) { instance_double(Dor::Services::Client::Object, find: cocina1) }
  let(:object_client2) { instance_double(Dor::Services::Client::Object, find: cocina2) }
  let(:params) do
    {
      druids:,
      groups:,
      user:,
      version_description: 'Changed dates'
    }.with_indifferent_access
  end

  before do
    allow(Ability).to receive(:new).and_return(ability)
    allow(VersionService).to receive(:open)
    allow(VersionService).to receive(:openable?).and_return(true)
    allow(Dor::Services::Client).to receive(:object).with(druids[0]).and_return(object_client1)
    allow(Dor::Services::Client).to receive(:object).with(druids[1]).and_return(object_client2)
  end

  context 'with manage ability' do
    let(:ability) { instance_double(Ability, can?: true) }

    it 'opens new versions' do
      described_class.perform_now(bulk_action.id, params)

      expect(VersionService).to have_received(:open).with(druid: anything,
                                                          description: 'Changed dates',
                                                          opening_user_name: user.to_s).twice
    end
  end

  context 'without manage ability' do
    let(:ability) { instance_double(Ability, can?: false) }

    it 'does not open new versions' do
      described_class.perform_now(bulk_action.id, params)

      expect(VersionService).not_to have_received(:open)
    end
  end
end
