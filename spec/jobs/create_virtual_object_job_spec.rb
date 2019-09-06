# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CreateVirtualObjectJob, type: :job do
  let(:client) do
    instance_double(Dor::Services::Client::Object, version: version_client, add_constituents: true)
  end
  let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, close: true) }
  let(:bulk_action) { create(:bulk_action) }

  describe '#perform' do
    subject(:perform) do
      described_class.perform_now(bulk_action.id,
                                  pids: '',
                                  create_virtual_object: { parent_druid: 'parent', child_druids: ['one', 'two'] })
    end

    before do
      allow(Dor::Services::Client).to receive(:object).and_return(client)
      allow(Dor).to receive(:find).and_return(instance_double(Dor::Item))
      allow(Ability).to receive(:new).and_return(ability)
    end

    context 'with authorization' do
      let(:ability) { instance_double(Ability, can?: true) }

      it 'calls the dor-services-app API' do
        perform
        expect(client).to have_received(:add_constituents).with(child_druids: ['druid:one', 'druid:two'])
        expect(version_client).to have_received(:close).exactly(3).times
      end
    end

    context 'without authorization' do
      let(:ability) { instance_double(Ability, can?: false) }

      it 'does not call the dor-services-app API' do
        perform
        expect(client).not_to have_received(:add_constituents)
        expect(version_client).not_to have_received(:close)
      end
    end
  end
end
