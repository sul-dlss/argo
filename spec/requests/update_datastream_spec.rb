# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Update a datastream' do
  before do
    allow(Dor).to receive(:find).with(pid).and_return(item)
    allow(item).to receive_messages(save: nil)
    allow(Argo::Indexer).to receive(:reindex_pid_remotely)
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
  end

  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model) }
  let(:cocina_model) do
    Cocina::Models.build(
      'label' => 'My Item',
      'version' => 1,
      'type' => Cocina::Models::Vocab.object,
      'externalIdentifier' => pid,
      'access' => {
        'access' => 'world'
      },
      'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
      'structural' => {},
      'identification' => {}
    )
  end
  let(:pid) { 'druid:bc123df4567' }
  let(:item) { Dor::Item.new pid: pid }
  let(:user) { create(:user) }
  let(:state_service) { instance_double(StateService, allows_modification?: true) }
  let(:xml) { '<contentMetadata/>' }
  let(:invalid_apo_xml) { '<hydra:isGovernedBy rdf:resource="info:fedora/druid:not_exist"/>' }

  context 'without management access' do
    before do
      sign_in user
    end

    it 'prevents access' do
      expect(item).not_to receive(:save)
      patch "/items/#{pid}/datastreams/contentMetadata", params: { content: xml }
      expect(response).to have_http_status(:forbidden)
    end
  end

  context 'when they have manage access' do
    before do
      sign_in user, groups: ['sdr:administrator-role']
    end

    it 'updates the datastream' do
      expect(item).to receive(:datastreams).and_return(
        'contentMetadata' => double(Dor::ContentMetadataDS, 'content=': xml)
      )
      expect(item).to receive(:save)
      patch "/items/#{pid}/datastreams/contentMetadata", params: { content: xml }
      expect(response).to redirect_to "/view/#{pid}"
    end

    it 'errors on empty xml' do
      expect { patch "/items/#{pid}/datastreams/contentMetadata", params: { content: ' ' } }.to raise_error(ArgumentError)
    end

    it 'does not update the datastream with malformed xml' do
      patch "/items/#{pid}/datastreams/contentMetadata", params: { content: '<this>isnt well formed.' }
      expect(item).not_to receive(:save)
      expect(Argo::Indexer).not_to receive(:reindex_pid_remotely)
      expect(response).to redirect_to "/view/#{pid}"
    end
  end
end
