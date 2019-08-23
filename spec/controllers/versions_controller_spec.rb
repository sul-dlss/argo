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
    wf   = instance_double(Dor::WorkflowDs)
    idmd_ds_content = '<test-xml/>'
    idmd_ng_xml = double(Nokogiri::XML::Document)
    allow(idmd).to receive(:"content_will_change!")
    allow(idmd_ng_xml).to receive(:to_xml).and_return idmd_ds_content
    allow(idmd).to receive(:ng_xml).and_return idmd_ng_xml
    allow(idmd).to receive(:"content=").with(idmd_ds_content)
    allow(apo).to receive(:pid).and_return('druid:apo')
    allow(wf).to receive(:content).and_return '<workflows objectId="druid:bx756pk3634"></workflows>'
    allow(item).to receive(:to_solr)
    allow(item).to receive(:save)
    allow(item).to receive(:datastreams).and_return('identityMetadata' => idmd, 'events' => Dor::EventsDS.new)
    allow(item).to receive(:admin_policy_object).and_return(apo)
    allow(ActiveFedora.solr.conn).to receive(:add)
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
      let(:vers_md_upd_info) { { significance: 'major', description: 'something', opening_user_name: user.to_s } }

      it 'calls dor-services to open a new version' do
        expect(item).to receive(:save)
        expect(ActiveFedora.solr.conn).to receive(:add)
        get :open, params: {
          item_id: pid,
          severity: vers_md_upd_info[:significance],
          description: vers_md_upd_info[:description]
        }

        expect(version_client).to have_received(:open).with(vers_md_upd_info: vers_md_upd_info)
      end
    end

    context 'without manage item access' do
      it 'returns a 403' do
        allow(controller).to receive(:authorize!).with(:manage_item, Dor::Item).and_raise(CanCan::AccessDenied)
        get :open, params: { item_id: pid, severity: 'major', description: 'something' }
        expect(response.code).to eq('403')
      end
    end
  end

  describe '#close' do
    context 'when they have manage_item access' do
      before do
        allow(Dor::Services::Client).to receive(:object).and_return(object_service)
        allow(controller).to receive(:authorize!).and_return(true)
      end

      let(:object_service) { instance_double(Dor::Services::Client::Object, version: version_service) }
      let(:version_service) { instance_double(Dor::Services::Client::ObjectVersion, close: true) }

      it 'calls dor-services to close the version' do
        version_metadata = double(Dor::VersionMetadataDS)
        allow(version_metadata).to receive(:current_version_id).and_return(2)
        allow(item).to receive(:versionMetadata).and_return(version_metadata)
        expect(version_metadata).to receive(:update_current_version)
        allow(item).to receive(:current_version).and_return('2')
        expect(item).to receive(:save)
        expect(ActiveFedora.solr.conn).to receive(:add)
        get :close, params: { item_id: pid, severity: 'major', description: 'something' }
        expect(version_service).to have_received(:close)
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

  describe '#create_obj' do
    it 'loads an APO object so that it has the appropriate model type (according to the solr doc)' do
      controller.params[:item_id] = 'druid:zt570tx3016'

      expect(Dor).to receive(:find).with('druid:zt570tx3016').and_call_original # override the earlier Dor.find expectation
      allow(Dor).to receive(:find).with('druid:hv992ry2431') # create_obj_and_apo will try to lookup the APO's APO
      subject.send(:create_obj)
      expect(subject.instance_variable_get(:@object).to_solr).to include('active_fedora_model_ssi' => 'Dor::AdminPolicyObject',
                                                                         'has_model_ssim' => 'info:fedora/afmodel:Dor_AdminPolicyObject')
    end

    it 'loads an Item object so that it has the appropriate model type (according to the solr doc)' do
      controller.params[:item_id] = 'druid:hj185vb7593'

      expect(Dor).to receive(:find).with('druid:hj185vb7593').and_call_original # override the earlier Dor.find expectation
      allow(Dor).to receive(:find).with('druid:ww057vk7675') # create_obj_and_apo will try to lookup the Item's APO
      subject.send(:create_obj)
      expect(subject.instance_variable_get(:@object).to_solr).to include('active_fedora_model_ssi' => 'Dor::Item',
                                                                         'has_model_ssim' => 'info:fedora/afmodel:Dor_Item')
    end
  end
end
