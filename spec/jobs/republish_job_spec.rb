# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RepublishJob do
  let(:druid) { 'druid:123' }
  let(:druids) { Array(druid) }
  let(:groups) { [] }
  let(:user) { instance_double(User, to_s: 'jcoyne85') }
  let(:bulk_action) { create(:bulk_action) }
  let(:object) { FactoryBot.create_for_repository(:persisted_item) }
  let(:object_client) { instance_double(Dor::Services::Client::Object, publish: true, find: object) }
  let(:workflow_client) { instance_double(Dor::Workflow::Client, lifecycle:) }
  let(:lifecycle) { Time.zone.now }

  before do
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
    allow(Dor::Workflow::Client).to receive(:new).and_return(workflow_client)

    described_class.perform_now(bulk_action.id,
                                druids:,
                                groups:,
                                user:)
  end

  after do
    FileUtils.rm(bulk_action.log_name)
  end

  context 'with already published item' do
    it 'publishes the object' do
      expect(object_client).to have_received(:publish).with(lane_id: 'low')
    end
  end

  context 'with never published item' do
    let(:lifecycle) { nil }

    it 'does not publish the object' do
      expect(object_client).not_to have_received(:publish)
    end
  end

  context 'with a collection' do
    let(:object) { FactoryBot.create_for_repository(:persisted_collection) }

    it 'publishes the object' do
      expect(object_client).to have_received(:publish)
    end
  end

  context 'with an APO' do
    let(:object) { FactoryBot.create_for_repository(:persisted_apo) }

    it 'does not publish the object' do
      expect(object_client).not_to have_received(:publish)
    end
  end

  context 'with an agreement' do
    let(:object) { FactoryBot.create_for_repository(:agreement) }

    it 'does not publish the object' do
      expect(object_client).not_to have_received(:publish)
    end
  end
end
