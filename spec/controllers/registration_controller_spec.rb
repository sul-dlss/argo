# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RegistrationController, type: :controller do
  before do
    @item = double(Dor::Item)
    sign_in user
    allow(user).to receive(:is_admin?).and_return(true)
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

      @item = double(Dor::Item)
      xml = Nokogiri::XML(content)
      allow(Dor).to receive(:find).and_return(@item)
      # using content metadata, but any datastream would do
      object_rights = double(Dor::ContentMetadataDS)
      allow(object_rights).to receive(:ng_xml).and_return xml
      allow(@item).to receive(:defaultObjectRights).and_return object_rights
      allow(@item).to receive(:default_rights).and_return 'stanford'
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

      @item = double(Dor::Item)
      xml = Nokogiri::XML(content)
      allow(Dor).to receive(:find).and_return(@item)
      # using content metadata, but any datastream would do
      object_rights = double(Dor::ContentMetadataDS)
      allow(object_rights).to receive(:ng_xml).and_return xml
      allow(@item).to receive(:defaultObjectRights).and_return object_rights
      allow(@item).to receive(:default_rights).and_return nil
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

      @item = double(Dor::Item)
      xml = Nokogiri::XML(content)
      allow(Dor).to receive(:find).and_return(@item)
      # using content metadata, but any datastream would do
      object_rights = double(Dor::ContentMetadataDS)
      allow(object_rights).to receive(:ng_xml).and_return xml
      allow(@item).to receive(:defaultObjectRights).and_return object_rights
      allow(@item).to receive(:default_rights).and_return 'world'
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

      @item = double(Dor::Item)
      xml = Nokogiri::XML(content)
      allow(Dor).to receive(:find).and_return(@item)
      # using content metadata, but any datastream would do
      object_rights = double(Dor::ContentMetadataDS)
      allow(object_rights).to receive(:ng_xml).and_return xml
      allow(@item).to receive(:defaultObjectRights).and_return object_rights
      allow(@item).to receive(:default_rights).and_return 'dark'
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
      @item = double(Dor::Item)
      xml = Nokogiri::XML(content)
      allow(Dor).to receive(:find).and_return(@item)
      # using content metadata, but any datastream would do
      object_rights = double(Dor::ContentMetadataDS)
      allow(object_rights).to receive(:ng_xml).and_return xml
      allow(@item).to receive(:defaultObjectRights).and_return object_rights
      allow(@item).to receive(:default_rights).and_return nil
      get 'rights_list', params: { apo_id: 'abc', format: :xml }
      expect(response.body.include?('World (APO default)')).to eq(false)
      expect(response.body.include?('Stanford (APO default)')).to eq(false)
      expect(response.body.include?('Citation Only (APO default)')).to eq(false)
      expect(response.body.include?('Dark (Preserve Only) (APO default)')).to eq(false)
    end
  end

  describe 'tracksheet' do
    it 'generates a tracking sheet with the right default name' do
      get 'tracksheet', params: { druid: 'xb482bw3979' }
      expect(response.headers['Content-Type']).to eq('pdf; charset=utf-8')
      expect(response.headers['content-disposition']).to eq('attachment; filename=tracksheet-1.pdf')
    end
    it 'generates a tracking sheet with the specified name (and sequence number)' do
      test_name = 'test_name'
      test_seq_no = 7
      get 'tracksheet', params: { druid: 'xb482bw3979', name: test_name, sequence: test_seq_no }
      expect(response.headers['content-disposition']).to eq("attachment; filename=#{test_name}-#{test_seq_no}.pdf")
    end
  end

  describe '#collection_list' do
    it 'handles invalid parameters' do
      expect { get 'collection_list' }.to raise_error(ArgumentError)
    end

    it 'handles a bogus APO' do
      get 'collection_list', params: { apo_id: 'druid:aa111bb2222' }
      expect(response).to have_http_status(:not_found)
    end

    it 'handles an APO with no collections' do
      get 'collection_list', params: { apo_id: 'druid:zt570tx3016', format: :json }
      data = JSON.parse(response.body)
      expect(data).to include('' => 'None')
      expect(data.length).to eq(1)
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

    context 'when the collections are not in solr' do
      it 'alpha-sorts the collection list by title, except for the "None" entry, which should come first' do
        apo_id = 'druid:fg464dn8891'

        # 'pb873ty1662' is a real object in our fixture data.  for the other two druids, we mock the
        # results of the calls to fedora.  the 'z' druid has a title that should cause it to sort first
        # after "None", and the 'a' druid has a title that should cause it to sort last.
        col_ids_for_apo = ['druid:pb873ty1662', 'druid:ab098cd7654', 'druid:zy123xw4567']
        allow(subject).to receive(:registration_collection_ids_for_apo).with(apo_id).and_return(col_ids_for_apo)
        mock_collection_z = double(Dor::Collection, label: 'A collection that sorts to the top')
        mock_collection_a = double(Dor::Collection, label: 'Ze last collection in ze list')
        allow(Dor).to receive(:find).with('druid:zy123xw4567').and_return(mock_collection_z)
        allow(Dor).to receive(:find).with('druid:pb873ty1662').and_call_original
        allow(Dor).to receive(:find).with('druid:ab098cd7654').and_return(mock_collection_a)

        get 'collection_list', params: { apo_id: apo_id, format: :json }
        data = JSON.parse(response.body)
        expect(data).to eq(
          '' => 'None',
          'druid:zy123xw4567' => 'A collection that sorts to the top (zy123xw4567)',
          'druid:pb873ty1662' => 'Annual report of the State Corporation Commission showing... (pb873ty1662)',
          'druid:ab098cd7654' => 'Ze last collection in ze list (ab098cd7654)'
        )
      end

      it 'does not include collections that are not found in Solr/Fedora' do
        missing_registration_collections = [
          'druid:kk203bw3276', 'druid:zx663qq1749', 'druid:nq832zg5474', 'druid:fb337wh0818', 'druid:kd973gk0505',
          'druid:jm980xw3297', 'druid:fz658ss5788', 'druid:vh782pm7216', 'druid:gg191kg3953'
        ]
        missing_registration_collections.each do |col_id|
          col_not_found_warning = "druid:fg464dn8891 lists collection #{col_id} for registration, but it wasn't found in Fedora."
          expect(Rails.logger).to receive(:warning).with(col_not_found_warning)
        end

        get 'collection_list', params: { apo_id: 'druid:fg464dn8891', format: :json }
        data = JSON.parse(response.body)
        expect(data['druid:pb873ty1662']).to eq 'Annual report of the State Corporation Commission showing... (pb873ty1662)'
        expect(data['druid:gg191kg3953']).to be nil
        expect(data.length).to eq(2)
      end
    end
  end

  describe '#workflow_list' do
    it 'handles an APO with multiple workflows, putting the default workflow first always' do
      get 'workflow_list', params: { apo_id: 'druid:ww057vk7675', format: :json }
      data = JSON.parse(response.body)
      expect(data.length).to eq(4)
      expect(data).to eq [Settings.apo.default_workflow_option, 'digitizationWF', 'dpgImageWF', 'goobiWF']
    end
  end

  context '#autocomplete' do
    it 'has no spec yet' do
      skip
    end
  end
end
