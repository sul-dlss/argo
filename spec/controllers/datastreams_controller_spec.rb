# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DatastreamsController, type: :controller do
  before do
    sign_in user
    allow(Dor).to receive(:find).with(pid).and_return(item)
    allow(item).to receive_messages(save: nil)
    allow(Argo::Indexer).to receive(:reindex_pid_remotely)
  end

  let(:pid) { 'druid:bc123df4567' }
  let(:item) { Dor::Item.new pid: pid }
  let(:user) { create(:user) }
  let(:state_service) { instance_double(StateService, allows_modification?: true) }

  describe '#datastream_update' do
    let(:xml) { '<contentMetadata/>' }
    let(:invalid_apo_xml) { '<hydra:isGovernedBy rdf:resource="info:fedora/druid:not_exist"/>' }

    context 'without management access' do
      before do
        allow(controller).to receive(:authorize!).with(:manage_item, Dor::Item).and_raise(CanCan::AccessDenied)
      end

      it 'prevents access' do
        expect(item).not_to receive(:save)
        post 'update', params: { id: 'contentMetadata', item_id: pid, content: xml }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when they have manage access' do
      before do
        allow(controller).to receive(:authorize!).and_return(true)
      end

      it 'updates the datastream' do
        expect(item).to receive(:datastreams).and_return(
          'contentMetadata' => double(Dor::ContentMetadataDS, 'content=': xml)
        )
        expect(item).to receive(:save)
        expect(controller).to receive(:authorize!).with(:manage_item, Dor::Item).and_return(true)
        post 'update', params: { id: 'contentMetadata', item_id: pid, content: xml }
        expect(response).to have_http_status(:found)
      end

      it 'errors on empty xml' do
        expect { post 'update', params: { id: 'contentMetadata', item_id: pid, content: ' ' } }.to raise_error(ArgumentError)
      end

      it 'errors on malformed xml' do
        expect { post 'update', params: { id: 'contentMetadata', item_id: pid, content: '<this>isnt well formed.' } }.to raise_error(ArgumentError)
      end
    end
  end
end
