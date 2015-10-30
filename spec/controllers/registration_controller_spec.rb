require 'spec_helper'

describe RegistrationController, :type => :controller do
  before :each do
    @item = double(Dor::Item)
    @current_user=double(:webauth_user, :login => 'sunetid', :logged_in? => true,:privgroup=>ADMIN_GROUPS.first)
    allow(@current_user).to receive(:is_admin).and_return(true)
    allow_any_instance_of(RegistrationController).to receive(:current_user).and_return(@current_user)
    allow(Dor::Item).to receive(:find).and_return(@item)
  end

  describe 'rights_list' do
    it 'should show Stanford as the default if Stanford is the read group and discover is world' do
      content=<<-XML
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

      @item=double(Dor::Item)
      xml=Nokogiri::XML(content)
      allow(Dor).to receive(:find).and_return(@item)
      #using content metadata, but any datastream would do
      object_rights=double(Dor::ContentMetadataDS)
      allow(object_rights).to receive(:ng_xml).and_return xml
      allow(@item).to receive(:defaultObjectRights).and_return object_rights
      get 'rights_list', :apo_id => 'abc', :format => :xml
      expect(response.body.include?("Stanford (APO default)")).to eq(true)
    end

    it 'should not show Stanford as the default if the read group is not Stanford' do
      content=<<-XML
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

      @item=double(Dor::Item)
      xml=Nokogiri::XML(content)
      allow(Dor).to receive(:find).and_return(@item)
      #using content metadata, but any datastream would do
      object_rights=double(Dor::ContentMetadataDS)
      allow(object_rights).to receive(:ng_xml).and_return xml
      allow(@item).to receive(:defaultObjectRights).and_return object_rights
      get 'rights_list', :apo_id => 'abc', :format => :xml
      expect(response.body.include?("Stanford (APO default)")).to eq(false)
    end

    it 'should show World as the default if discover and read are both world' do
      content=<<-XML
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

      @item=double(Dor::Item)
      xml=Nokogiri::XML(content)
      allow(Dor).to receive(:find).and_return(@item)
      #using content metadata, but any datastream would do
      object_rights=double(Dor::ContentMetadataDS)
      allow(object_rights).to receive(:ng_xml).and_return xml
      allow(@item).to receive(:defaultObjectRights).and_return object_rights
      get 'rights_list', :apo_id => 'abc', :format => :xml
      expect(response.body.include?("World (APO default)")).to eq(true)
    end

    it 'should show Dark as the default if discover and read are both none' do
      content=<<-XML
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

      @item=double(Dor::Item)
      xml=Nokogiri::XML(content)
      allow(Dor).to receive(:find).and_return(@item)
      #using content metadata, but any datastream would do
      object_rights=double(Dor::ContentMetadataDS)
      allow(object_rights).to receive(:ng_xml).and_return xml
      allow(@item).to receive(:defaultObjectRights).and_return object_rights
      get 'rights_list', :apo_id => 'abc', :format => :xml
      expect(response.body.include?("Dark (APO default)")).to eq(true)
    end

    it 'should show Citation Only as the default if discover is world and read is none' do
      content=<<-XML
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

      @item=double(Dor::Item)
      xml=Nokogiri::XML(content)
      allow(Dor).to receive(:find).and_return(@item)
      #using content metadata, but any datastream would do
      object_rights=double(Dor::ContentMetadataDS)
      allow(object_rights).to receive(:ng_xml).and_return xml
      allow(@item).to receive(:defaultObjectRights).and_return object_rights
      get 'rights_list', :apo_id => 'abc', :format => :xml
      expect(response.body.include?("Citation Only (APO default)")).to eq(true)
    end

    it 'should show no default if there is no xml' do
      content=''
      @item=double(Dor::Item)
      xml=Nokogiri::XML(content)
      allow(Dor).to receive(:find).and_return(@item)
      #using content metadata, but any datastream would do
      object_rights=double(Dor::ContentMetadataDS)
      allow(object_rights).to receive(:ng_xml).and_return xml
      allow(@item).to receive(:defaultObjectRights).and_return object_rights
      get 'rights_list', :apo_id => 'abc', :format => :xml
      expect(response.body.include?("World (APO default)")).to eq(false)
      expect(response.body.include?("Stanford (APO default)")).to eq(false)
      expect(response.body.include?("Citation Only (APO default)")).to eq(false)
      expect(response.body.include?("Dark (APO default)")).to eq(false)
    end
  end

  describe 'tracksheet' do
    it 'should generate a tracking sheet with the right default name' do
      get 'tracksheet', :druid => 'ww057vk7675'
      expect(response.headers["Content-Type"]).to eq("pdf; charset=utf-8")
      expect(response.headers["content-disposition"]).to eq("attachment; filename=tracksheet-1.pdf")
    end
    it 'should generate a tracking sheet with the specified name (and sequence number)' do
      test_name = 'test_name'
      test_seq_no = 7
      get 'tracksheet', :druid => 'ww057vk7675', :name => test_name, :sequence => test_seq_no
      expect(response.headers["content-disposition"]).to eq("attachment; filename=#{test_name}-#{test_seq_no}.pdf")
    end
  end
end
