# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Update a datastream' do
  before do
    allow(Argo::Indexer).to receive(:reindex_druid_remotely)
    allow(Repository).to receive(:find).and_return(cocina_model)
  end

  let(:cocina_model) { build(:dro) }
  let(:druid) { 'druid:bc123df4567' }
  let(:user) { create(:user) }
  let(:state_service) { instance_double(StateService, allows_modification?: true) }
  let(:xml) { '<contentMetadata/>' }
  let(:invalid_apo_xml) { '<hydra:isGovernedBy rdf:resource="info:fedora/druid:not_exist"/>' }

  context 'without management access' do
    before do
      sign_in user
    end

    it 'prevents access' do
      patch "/items/#{druid}/datastreams/contentMetadata", params: { content: xml }
      expect(response).to have_http_status(:forbidden)
      expect(Argo::Indexer).not_to have_received(:reindex_druid_remotely)
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

      before do
        allow(Dor::Services::Client).to receive(:object).and_return(object_client)
      end

      it 'updates the datastream' do
        patch "/items/#{druid}/datastreams/contentMetadata", params: { content: xml }
        expect(response).to redirect_to "/view/#{druid}"
        expect(metadata_client).to have_received(:legacy_update)
        expect(Argo::Indexer).to have_received(:reindex_druid_remotely)
      end
    end

    it 'errors on empty xml' do
      expect { patch "/items/#{druid}/datastreams/contentMetadata", params: { content: ' ' } }.to raise_error(ArgumentError)
    end

    it 'does not update the datastream with malformed xml' do
      patch "/items/#{druid}/datastreams/contentMetadata", params: { content: '<this>isnt well formed.' }
      expect(Argo::Indexer).not_to have_received(:reindex_druid_remotely)
      expect(response).to redirect_to "/view/#{druid}"
    end

    context 'for a datastream that fails validation' do
      let(:json_response) do
        <<~JSON
          {"errors":
            [{
              "status":"422",
              "title":"problem",
              "detail":"MODS is not valid: details"
            }]
          }
        JSON
      end

      before do
        stub_request(:patch, "#{Settings.dor_services.url}/v1/objects/druid:bc123df4567/metadata/legacy")
          .to_return(status: 422, body: json_response, headers: { 'content-type' => 'application/vnd.api+json' })
      end

      it 'does not update the datastream' do
        patch "/items/#{druid}/datastreams/contentMetadata", params: { content: xml }
        expect(response).to redirect_to "/view/#{druid}"
        expect(flash[:error]).to eq 'MODS is not valid: details'
        expect(Argo::Indexer).not_to have_received(:reindex_druid_remotely)
      end
    end
  end

  describe 'DatastreamsController.endpoint_for_datastream' do
    subject { DatastreamsController.endpoint_for_datastream(datastream) }

    let(:datastream) { 'descMetadata' }

    it { is_expected.to eq 'descriptive' }
  end
end
