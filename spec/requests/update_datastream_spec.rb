# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Update a datastream' do
  before do
    allow(Argo::Indexer).to receive(:reindex_pid_remotely)
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
  end

  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model) }
  let(:cocina_model) do
    Cocina::Models.build({
                           'label' => 'My Item',
                           'version' => 1,
                           'type' => Cocina::Models::Vocab.object,
                           'externalIdentifier' => pid,
                           'access' => {},
                           'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
                           'structural' => {},
                           'identification' => {}
                         })
  end
  let(:pid) { 'druid:bc123df4567' }
  let(:user) { create(:user) }
  let(:state_service) { instance_double(StateService, allows_modification?: true) }
  let(:xml) { '<contentMetadata/>' }
  let(:invalid_apo_xml) { '<hydra:isGovernedBy rdf:resource="info:fedora/druid:not_exist"/>' }

  context 'without management access' do
    before do
      sign_in user
    end

    it 'prevents access' do
      patch "/items/#{pid}/datastreams/contentMetadata", params: { content: xml }
      expect(response).to have_http_status(:forbidden)
      expect(Argo::Indexer).not_to have_received(:reindex_pid_remotely)
    end
  end

  context 'when they have manage access' do
    before do
      sign_in user, groups: ['sdr:administrator-role']
    end

    context 'for a common datastream' do
      let(:object_client) do
        instance_double(Dor::Services::Client::Object, find: cocina_model, metadata: metadata_client)
      end
      let(:metadata_client) do
        instance_double(Dor::Services::Client::Metadata, legacy_update: true)
      end

      it 'updates the datastream' do
        patch "/items/#{pid}/datastreams/contentMetadata", params: { content: xml }
        expect(response).to redirect_to "/view/#{pid}"
        expect(metadata_client).to have_received(:legacy_update)
        expect(Argo::Indexer).to have_received(:reindex_pid_remotely)
      end
    end

    it 'errors on empty xml' do
      expect { patch "/items/#{pid}/datastreams/contentMetadata", params: { content: ' ' } }.to raise_error(ArgumentError)
    end

    it 'does not update the datastream with malformed xml' do
      patch "/items/#{pid}/datastreams/contentMetadata", params: { content: '<this>isnt well formed.' }
      expect(Argo::Indexer).not_to have_received(:reindex_pid_remotely)
      expect(response).to redirect_to "/view/#{pid}"
    end

    context 'for a datastream that fails validation' do
      let(:object_client) do
        instance_double(Dor::Services::Client::Object, find: cocina_model, metadata: metadata_client)
      end
      let(:metadata_client) do
        instance_double(Dor::Services::Client::Metadata, legacy_update: true)
      end

      before do
        allow(metadata_client).to receive(:legacy_update).and_raise(Dor::Services::Client::UnexpectedResponse)
      end

      it 'does not update the datastream' do
        patch "/items/#{pid}/datastreams/contentMetadata", params: { content: xml }
        expect(response).to redirect_to "/view/#{pid}"
        expect(Argo::Indexer).not_to have_received(:reindex_pid_remotely)
      end
    end
  end

  describe 'DatastreamsController.endpoint_for_datastream' do
    subject { DatastreamsController.endpoint_for_datastream(datastream) }

    let(:datastream) { 'descMetadata' }

    it { is_expected.to eq 'descriptive' }
  end
end
