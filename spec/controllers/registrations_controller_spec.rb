# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RegistrationsController, type: :controller do
  before do
    sign_in user
    allow(user).to receive(:admin?).and_return(true)
  end

  let(:user) { create(:user) }

  describe 'rights_list' do
    it 'shows Stanford as the default if Stanford is the read group and discover is world' do
      content = <<-XML
      <?xml version="1.0"?>
      <rightsMetadata>
        <copyright>
          <human type="copyright">This work is in the Public Domain.</human>
        </copyright>
        <access type="discover">
          <machine>
            <world/>
          </machine>
        </access>
        <access type="read">
          <machine>
            <group>Stanford</group>
          </machine>
        </access>
        <use>
          <human type="creativecommons">Attribution Share Alike license</human>
          <machine type="creativecommons">by-sa</machine>
        </use>
      </rightsMetadata>
      XML

      item = instance_double(Dor::AdminPolicyObject)
      xml = Nokogiri::XML(content)
      allow(Dor).to receive(:find).and_return(item)
      # using content metadata, but any datastream would do
      object_rights = instance_double(Dor::ContentMetadataDS)
      allow(object_rights).to receive(:ng_xml).and_return xml
      allow(item).to receive(:defaultObjectRights).and_return object_rights
      allow(item).to receive(:default_rights).and_return 'stanford'
      get 'rights_list', params: { apo_id: 'abc', format: :xml }
      expect(response.body.include?('Stanford (APO default)')).to eq(true)
    end

    it 'does not show Stanford as the default if the read group is not Stanford' do
      content = <<-XML
      <?xml version="1.0"?>
      <rightsMetadata>
        <copyright>
          <human type="copyright">This work is in the Public Domain.</human>
        </copyright>
        <access type="discover">
          <machine>
            <world/>
          </machine>
        </access>
        <access type="read">
          <machine>
            <group>Berkeley</group>
          </machine>
        </access>
        <use>
          <human type="creativecommons">Attribution Share Alike license</human>
          <machine type="creativecommons">by-sa</machine>
        </use>
      </rightsMetadata>
      XML

      item = instance_double(Dor::AdminPolicyObject)
      xml = Nokogiri::XML(content)
      allow(Dor).to receive(:find).and_return(item)
      # using content metadata, but any datastream would do
      object_rights = instance_double(Dor::ContentMetadataDS)
      allow(object_rights).to receive(:ng_xml).and_return xml
      allow(item).to receive(:defaultObjectRights).and_return object_rights
      allow(item).to receive(:default_rights).and_return nil
      get 'rights_list', params: { apo_id: 'abc', format: :xml }
      expect(response.body.include?('Stanford (APO default)')).to eq(false)
    end

    it 'shows World as the default if discover and read are both world' do
      content = <<-XML
      <?xml version="1.0"?>
      <rightsMetadata>
        <copyright>
          <human type="copyright">This work is in the Public Domain.</human>
        </copyright>
        <access type="discover">
          <machine>
            <world/>
          </machine>
        </access>
        <access type="read">
          <machine>
            <world/>
          </machine>
        </access>
        <use>
          <human type="creativecommons">Attribution Share Alike license</human>
          <machine type="creativecommons">by-sa</machine>
        </use>
      </rightsMetadata>
      XML

      item = instance_double(Dor::AdminPolicyObject)
      xml = Nokogiri::XML(content)
      allow(Dor).to receive(:find).and_return(item)
      # using content metadata, but any datastream would do
      object_rights = instance_double(Dor::ContentMetadataDS)
      allow(object_rights).to receive(:ng_xml).and_return xml
      allow(item).to receive(:defaultObjectRights).and_return object_rights
      allow(item).to receive(:default_rights).and_return 'world'
      get 'rights_list', params: { apo_id: 'abc', format: :xml }
      expect(response.body.include?('World (APO default)')).to eq(true)
    end

    it 'shows Dark as the default if discover and read are both none' do
      content = <<-XML
      <?xml version="1.0"?>
      <rightsMetadata>
        <copyright>
          <human type="copyright">This work is in the Public Domain.</human>
        </copyright>
        <access type="discover">
          <machine>
            <none/>
          </machine>
        </access>
        <access type="read">
          <machine>
            <none/>
          </machine>
        </access>
        <use>
          <human type="creativecommons">Attribution Share Alike license</human>
          <machine type="creativecommons">by-sa</machine>
        </use>
      </rightsMetadata>
      XML

      item = instance_double(Dor::AdminPolicyObject)
      xml = Nokogiri::XML(content)
      allow(Dor).to receive(:find).and_return(item)
      # using content metadata, but any datastream would do
      object_rights = instance_double(Dor::ContentMetadataDS)
      allow(object_rights).to receive(:ng_xml).and_return xml
      allow(item).to receive(:defaultObjectRights).and_return object_rights
      allow(item).to receive(:default_rights).and_return 'dark'
      get 'rights_list', params: { apo_id: 'abc', format: :xml }
      expect(response.body.include?('Dark (Preserve Only) (APO default)')).to eq(true)
    end

    it 'shows Citation Only as the default if discover is world and read is none' do
      content = <<-XML
      <?xml version="1.0"?>
      <rightsMetadata>
        <copyright>
          <human type="copyright">This work is in the Public Domain.</human>
        </copyright>
        <access type="discover">
          <machine>
            <world/>
          </machine>
        </access>
        <access type="read">
          <machine>
            <none/>
          </machine>
        </access>
        <use>
          <human type="creativecommons">Attribution Share Alike license</human>
          <machine type="creativecommons">by-sa</machine>
        </use>
      </rightsMetadata>
      XML

      object_rights = instance_double(Dor::ContentMetadataDS, ng_xml: Nokogiri::XML(content))
      apo = instance_double(Dor::AdminPolicyObject, defaultObjectRights: object_rights, default_rights: 'none')
      allow(Dor).to receive(:find).and_return(apo)
      # using content metadata, but any datastream would do
      get 'rights_list', params: { apo_id: 'abc', format: :xml }
      expect(response.body.include?('Citation Only (APO default)')).to eq(true)
    end

    it 'shows no default if there is no xml' do
      content = ''
      item = instance_double(Dor::AdminPolicyObject)
      xml = Nokogiri::XML(content)
      allow(Dor).to receive(:find).and_return(item)
      # using content metadata, but any datastream would do
      object_rights = instance_double(Dor::ContentMetadataDS)
      allow(object_rights).to receive(:ng_xml).and_return xml
      allow(item).to receive(:defaultObjectRights).and_return object_rights
      allow(item).to receive(:default_rights).and_return nil
      get 'rights_list', params: { apo_id: 'abc', format: :xml }
      expect(response.body.include?('World (APO default)')).to eq(false)
      expect(response.body.include?('Stanford (APO default)')).to eq(false)
      expect(response.body.include?('Citation Only (APO default)')).to eq(false)
      expect(response.body.include?('Dark (Preserve Only) (APO default)')).to eq(false)
    end
  end

  describe 'tracksheet' do
    before do
      allow(TrackSheet).to receive(:new).with([druid]).and_return(track_sheet)
    end

    let(:druid) { 'xb482ww9999' }
    let(:track_sheet) { instance_double(TrackSheet, generate_tracking_pdf: doc) }
    let(:doc) { instance_double(Prawn::Document, render: '') }

    it 'generates a tracking sheet with the right default name' do
      get 'tracksheet', params: { druid: druid }
      expect(response.headers['Content-Type']).to eq('pdf; charset=utf-8')
      expect(response.headers['content-disposition']).to eq('attachment; filename=tracksheet-1.pdf')
    end

    it 'generates a tracking sheet with the specified name (and sequence number)' do
      test_name = 'test_name'
      test_seq_no = 7
      get 'tracksheet', params: { druid: druid, name: test_name, sequence: test_seq_no }
      expect(response.headers['content-disposition']).to eq("attachment; filename=#{test_name}-#{test_seq_no}.pdf")
    end
  end

  describe '#collection_list' do
    let(:apo_id) { 'druid:fg464dn8891' }

    it 'handles invalid parameters' do
      expect { get 'collection_list' }.to raise_error(ArgumentError)
    end

    context 'when there are no collections' do
      before do
        allow(subject).to receive(:registration_collection_ids_for_apo).with(apo_id).and_return([])
      end

      it 'shows "None"' do
        get 'collection_list', params: { apo_id: apo_id, format: :json }
        data = JSON.parse(response.body)
        expect(data).to include('' => 'None')
        expect(data.length).to eq(1)
      end
    end

    context 'when the collections are in solr' do
      before do
        allow(Dor::SearchService).to receive(:query).and_return(solr_response)
        allow(subject).to receive(:registration_collection_ids_for_apo).with(apo_id).and_return(col_ids_for_apo)
      end

      let(:col_ids_for_apo) { ['druid:pb873ty1662'] }
      let(:apo_id) { 'druid:fg464dn8891' }
      let(:solr_response) do
        { 'response' => { 'docs' => [solr_doc] } }
      end
      let(:solr_doc) do
        {
          'sw_display_title_tesim' => [
            'Annual report of the State Corporation Commission showing the condition ' \
            'of the incorporated state banks and other institutions operating in ' \
            'Virginia at the close of business'
          ]
        }
      end

      it 'alpha-sorts the collection list by title, except for the "None" entry, which should come first' do
        get 'collection_list', params: { apo_id: apo_id, format: :json }
        data = JSON.parse(response.body)
        expect(data).to eq(
          '' => 'None',
          'druid:pb873ty1662' => 'Annual report of the State Corporation Commission showing... (pb873ty1662)'
        )
      end
    end
  end

  describe '#workflow_list' do
    let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model) }
    let(:cocina_model) do
      Cocina::Models.build(
        'label' => 'The APO',
        'version' => 1,
        'type' => Cocina::Models::Vocab.admin_policy,
        'externalIdentifier' => apo_id,
        'administrative' => {
          hasAdminPolicy: 'druid:hv992ry2431',
          registrationWorkflow: ['digitizationWF', 'dpgImageWF', Settings.apo.default_workflow_option, 'goobiWF']
        }
      )
    end
    let(:apo_id) { 'druid:zt570tx3016' }

    before do
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    end

    it 'handles an APO with multiple workflows, putting the default workflow first always' do
      get 'workflow_list', params: { apo_id: apo_id, format: :json }
      data = JSON.parse(response.body)
      expect(data).to eq [Settings.apo.default_workflow_option, 'digitizationWF', 'dpgImageWF', 'goobiWF']
    end
  end
end
