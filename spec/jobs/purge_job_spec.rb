# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PurgeJob do
  let(:druids) { ['druid:bb111cc2222', 'druid:cc111dd2222'] }
  let(:groups) { [] }
  let(:user) { create(:user) }
  let(:submitted) { false }
  let(:bulk_action) { create(:bulk_action, user:) }
  let(:cocina1) do
    build(:dro_with_metadata, id: druids[0])
  end
  let(:cocina2) do
    build(:dro_with_metadata, id: druids[1])
  end
  let(:object_client1) { instance_double(Dor::Services::Client::Object, find: cocina1) }
  let(:object_client2) { instance_double(Dor::Services::Client::Object, find: cocina2) }

  before do
    allow(Ability).to receive(:new).and_return(ability)
    allow(WorkflowService).to receive(:submitted?).and_return(submitted)
    allow(Dor::Services::Client).to receive(:object).with(druids[0]).and_return(object_client1)
    allow(Dor::Services::Client).to receive(:object).with(druids[1]).and_return(object_client2)
    allow(PurgeService).to receive(:purge)

    described_class.perform_now(bulk_action.id,
                                druids:,
                                groups:,
                                user:)
  end

  after do
    FileUtils.rm(bulk_action.log_name)
  end

  context 'with manage ability' do
    let(:ability) { instance_double(Ability, can?: true) }

    context 'when submitted' do
      let(:submitted) { true }

      it "doesn't purge" do
        expect(PurgeService).not_to have_received(:purge)
      end
    end

    context 'when not submitted' do
      let(:submitted) { false }

      it 'purges objects' do
        expect(PurgeService).to have_received(:purge).with(druid: druids[0], user_name: user.login)
        expect(PurgeService).to have_received(:purge).with(druid: druids[1], user_name: user.login)
      end
    end
  end

  context 'without manage ability' do
    let(:ability) { instance_double(Ability, can?: false) }

    it "doesn't purge" do
      expect(PurgeService).not_to have_received(:purge)
    end
  end
end
