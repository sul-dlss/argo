# frozen_string_literal: true

require 'rails_helper'

RSpec.describe VersionsController, type: :controller do
  let(:pid) { 'druid:bc123df4567' }
  let(:object_service) { instance_double(Dor::Services::Client::Object, find: cocina_model) }
  let(:cocina_model) do
    Cocina::Models.build(
      'label' => 'My Item',
      'version' => 2,
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

  before do
    allow_any_instance_of(User).to receive(:roles).and_return([])
    sign_in user
    allow(Argo::Indexer).to receive(:reindex_pid_remotely)
    allow(Dor::Services::Client).to receive(:object).and_return(object_service)
  end

  let(:user) { create(:user) }

  describe '#open' do
    context 'when they have manage_item access' do
      before do
        allow(controller).to receive(:authorize!).and_return(true)
      end

      let(:object_service) { instance_double(Dor::Services::Client::Object, version: version_client, find: cocina_model) }
      let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, open: true) }
      let(:options) { { significance: 'major', description: 'something', opening_user_name: user.to_s } }

      it 'calls dor-services to open a new version' do
        expect(Argo::Indexer).to receive(:reindex_pid_remotely)

        get :open, params: {
          item_id: pid,
          significance: options[:significance],
          description: options[:description]
        }

        expect(version_client).to have_received(:open).with(**options)
      end
    end

    context 'without manage item access' do
      it 'returns a 403' do
        allow(controller).to receive(:authorize!).with(:manage_item, Cocina::Models::DRO).and_raise(CanCan::AccessDenied)
        get :open, params: { item_id: pid, significance: 'major', description: 'something' }
        expect(response.code).to eq('403')
      end
    end
  end

  describe '#close' do
    context 'when they have manage_item access' do
      before do
        allow(controller).to receive(:authorize!).and_return(true)
      end

      let(:object_service) { instance_double(Dor::Services::Client::Object, version: version_service, find: cocina_model) }
      let(:version_service) { instance_double(Dor::Services::Client::ObjectVersion, close: true) }

      it 'calls dor-services to close the version' do
        expect(Argo::Indexer).to receive(:reindex_pid_remotely)

        get :close, params: { item_id: pid, significance: 'major', description: 'something' }
        expect(flash[:notice]).to eq "Version 2 of #{pid} has been closed!"
        expect(version_service).to have_received(:close).with(description: 'something', significance: 'major', user_name: user.to_s)
      end
    end

    context 'without manage access' do
      let(:object_service) { instance_double(Dor::Services::Client::Object, find: cocina_model) }

      it 'returns a 403' do
        allow(controller).to receive(:authorize!).with(:manage_item, Cocina::Models::DRO).and_raise(CanCan::AccessDenied)
        get :close, params: { item_id: pid }
        expect(response.code).to eq('403')
      end
    end
  end
end
