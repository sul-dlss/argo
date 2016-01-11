require 'spec_helper'

describe RegistrationController, :type => :controller do
  before :each do
    @item = double(Dor::Item)
    @current_user = double(:webauth_user, :login => 'sunetid', :logged_in? => true, :privgroup => ADMIN_GROUPS.first)
    allow(@current_user).to receive(:is_admin).and_return(true)
    allow(controller).to receive(:current_user).and_return(@current_user)
    allow(Dor::Item).to receive(:find).and_return(@item)
  end

  describe 'rights_list' do
    it 'should show Stanford as the default if Stanford is the read group and discover is world' do
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
      get 'rights_list', :apo_id => 'abc', :format => :xml
      expect(response.body.include?('Stanford (APO default)')).to eq(true)
    end

    it 'should not show Stanford as the default if the read group is not Stanford' do
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
      get 'rights_list', :apo_id => 'abc', :format => :xml
      expect(response.body.include?('Stanford (APO default)')).to eq(false)
    end

    it 'should show World as the default if discover and read are both world' do
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
      get 'rights_list', :apo_id => 'abc', :format => :xml
      expect(response.body.include?('World (APO default)')).to eq(true)
    end

    it 'should show Dark as the default if discover and read are both none' do
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
      get 'rights_list', :apo_id => 'abc', :format => :xml
      expect(response.body.include?('Dark (Preserve Only) (APO default)')).to eq(true)
    end

    it 'should show Citation Only as the default if discover is world and read is none' do
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

      @item = double(Dor::Item)
      xml = Nokogiri::XML(content)
      allow(Dor).to receive(:find).and_return(@item)
      # using content metadata, but any datastream would do
      object_rights = double(Dor::ContentMetadataDS)
      allow(object_rights).to receive(:ng_xml).and_return xml
      allow(@item).to receive(:defaultObjectRights).and_return object_rights
      get 'rights_list', :apo_id => 'abc', :format => :xml
      expect(response.body.include?('Citation Only (APO default)')).to eq(true)
    end

    it 'should show no default if there is no xml' do
      content = ''
      @item = double(Dor::Item)
      xml = Nokogiri::XML(content)
      allow(Dor).to receive(:find).and_return(@item)
      # using content metadata, but any datastream would do
      object_rights = double(Dor::ContentMetadataDS)
      allow(object_rights).to receive(:ng_xml).and_return xml
      allow(@item).to receive(:defaultObjectRights).and_return object_rights
      get 'rights_list', :apo_id => 'abc', :format => :xml
      expect(response.body.include?('World (APO default)')).to eq(false)
      expect(response.body.include?('Stanford (APO default)')).to eq(false)
      expect(response.body.include?('Citation Only (APO default)')).to eq(false)
      expect(response.body.include?('Dark (Preserve Only) (APO default)')).to eq(false)
    end
  end

  describe 'tracksheet' do
    it 'should generate a tracking sheet with the right default name' do
      get 'tracksheet', :druid => 'xb482bw3979'
      expect(response.headers['Content-Type']).to eq('pdf; charset=utf-8')
      expect(response.headers['content-disposition']).to eq('attachment; filename=tracksheet-1.pdf')
    end
    it 'should generate a tracking sheet with the specified name (and sequence number)' do
      test_name = 'test_name'
      test_seq_no = 7
      get 'tracksheet', :druid => 'xb482bw3979', :name => test_name, :sequence => test_seq_no
      expect(response.headers['content-disposition']).to eq("attachment; filename=#{test_name}-#{test_seq_no}.pdf")
    end
  end

  describe '#collection_list' do
    it 'should handle invalid parameters' do
      expect { get 'collection_list' }.to raise_error(ArgumentError)
    end

    it 'should handle a bogus APO' do
      get 'collection_list', apo_id: 'druid:aa111bb2222'
      expect(response).to have_http_status(:not_found)
    end

    it 'should handle an APO with no collections' do
      get 'collection_list', apo_id: 'druid:zt570tx3016', format: :json
      data = JSON.parse(response.body)
      expect(data).to include('' => 'None')
      expect(data.length).to eq(1)
    end

    it 'should handle an APO with some collections both found and not found in Solr/Fedora' do
      get 'collection_list', apo_id: 'druid:fg464dn8891', format: :json
      data = JSON.parse(response.body)
      expect(data['druid:pb873ty1662']).to start_with 'Annual report of the State Corporation Commission'
      expect(data['druid:gg191kg3953']).to eq 'Unknown Collection (gg191kg3953)'
      expect(data.length).to eq(11)
    end
  end

  describe '#workflow_list' do
    it 'should handle an APO with a single default workflow' do
      get 'workflow_list', apo_id: 'druid:fg464dn8891', format: :json
      data = JSON.parse(response.body)
      expect(data).to include 'dpgImageWF'
      expect(data.length).to eq(1)
    end

    it 'should handle an APO with multiple workfllows' do
      get 'workflow_list', apo_id: 'druid:ww057vk7675', format: :json
      data = JSON.parse(response.body)
      expect(data).to include 'digitizationWF'
      expect(data).to include 'dpgImageWF'
      expect(data.length).to eq(2)
      expect(data.sort).to eq(data)
    end
  end

  context '#autocomplete' do
    it 'has no spec yet' do
      skip
    end
  end
end
