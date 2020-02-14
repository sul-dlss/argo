# frozen_string_literal: true

require 'rails_helper'

RSpec.describe VersionsController, type: :controller do
  let(:pid) { 'druid:oo201oo0001' }
  let(:item) { Dor::Item.new pid: pid }

  before do
    allow_any_instance_of(User).to receive(:roles).and_return([])
    sign_in user
    allow(Dor).to receive(:find).with(pid).and_return(item)
    idmd = double
    apo  = double
    idmd_ds_content = '<test-xml/>'
    idmd_ng_xml = double(Nokogiri::XML::Document)
    allow(idmd).to receive(:"content_will_change!")
    allow(idmd_ng_xml).to receive(:to_xml).and_return idmd_ds_content
    allow(idmd).to receive(:ng_xml).and_return idmd_ng_xml
    allow(idmd).to receive(:"content=").with(idmd_ds_content)
    allow(apo).to receive(:pid).and_return('druid:apo')
    allow(item).to receive(:to_solr)
    allow(item).to receive(:save)
    allow(item).to receive(:datastreams).and_return('identityMetadata' => idmd, 'events' => Dor::EventsDS.new)
    allow(item).to receive(:admin_policy_object).and_return(apo)
    allow(Argo::Indexer).to receive(:reindex_pid_remotely)
  end

  let(:user) { create(:user) }

  describe '#open' do
    context 'when they have manage_item access' do
      before do
        allow(controller).to receive(:authorize!).and_return(true)
        allow(Dor::Services::Client).to receive(:object).and_return(client)
      end

      let(:client) { instance_double(Dor::Services::Client::Object, version: version_client) }
      let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, open: true) }
      let(:options) { { significance: 'major', description: 'something', opening_user_name: user.to_s } }

      it 'calls dor-services to open a new version' do
        expect(item).to receive(:save)
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
        allow(controller).to receive(:authorize!).with(:manage_item, Dor::Item).and_raise(CanCan::AccessDenied)
        get :open, params: { item_id: pid, significance: 'major', description: 'something' }
        expect(response.code).to eq('403')
      end
    end
  end

  describe '#close' do
    context 'when they have manage_item access' do
      before do
        allow(Dor::Services::Client).to receive(:object).and_return(object_service)
        allow(controller).to receive(:authorize!).and_return(true)
        allow(item).to receive(:current_version).and_return('2')
      end

      let(:object_service) { instance_double(Dor::Services::Client::Object, version: version_service) }
      let(:version_service) { instance_double(Dor::Services::Client::ObjectVersion, close: true) }

      it 'calls dor-services to close the version' do
        expect(item).to receive(:save)
        expect(Argo::Indexer).to receive(:reindex_pid_remotely)

        get :close, params: { item_id: pid, significance: 'major', description: 'something' }
        expect(flash[:notice]).to eq "Version 2 of #{pid} has been closed!"
        expect(version_service).to have_received(:close).with(description: 'something', significance: 'major')
      end
    end

    context 'without manage access' do
      it 'returns a 403' do
        allow(controller).to receive(:authorize!).with(:manage_item, Dor::Item).and_raise(CanCan::AccessDenied)
        get :close, params: { item_id: pid }
        expect(response.code).to eq('403')
      end
    end
  end
end
