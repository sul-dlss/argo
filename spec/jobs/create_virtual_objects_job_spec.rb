# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CreateVirtualObjectsJob, type: :job do
  let(:client) do
    instance_double(Dor::Services::Client::VirtualObjects, create: true)
  end
  let(:bulk_action) { create(:bulk_action) }

  before do
    allow(BulkAction).to receive(:find).and_return(bulk_action)
  end

  describe '#perform' do
    subject(:perform) do
      described_class.perform_now(bulk_action.id,
                                  pids: '',
                                  create_virtual_objects: 'parent,one,two')
    end

    before do
      allow(Dor::Services::Client).to receive(:virtual_objects).and_return(client)
      allow(Dor).to receive(:find).and_return(instance_double(Dor::Item))
      allow(Ability).to receive(:new).and_return(ability)
    end

    context 'with authorization' do
      let(:ability) { instance_double(Ability, can?: true) }

      it 'calls the dor-services-app API' do
        perform
        expect(client).to have_received(:create).with(virtual_objects: [{ parent_id: 'parent', child_ids: ['one', 'two'] }])
      end

      it 'increments the success counter w/ the number of virtual objects successfully created' do
        allow(bulk_action).to receive(:increment!)
        perform
        expect(bulk_action).to have_received(:increment!).with(:druid_count_success, 1).once
      end
    end

    context 'without authorization' do
      let(:ability) { instance_double(Ability, can?: false) }

      it 'does not call the dor-services-app API' do
        perform
        expect(client).not_to have_received(:create)
      end
    end
  end
end
