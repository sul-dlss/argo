require 'spec_helper'
describe RegistrationController do
  before :each do
    @item = double(Dor::Item)
    @current_user=double(:webauth_user, :login => 'sunetid', :logged_in? => true,:privgroup=>ADMIN_GROUPS.first)
    @current_user.stub(:is_admin).and_return(true)
    RegistrationController.any_instance.stub(:current_user).and_return(@current_user)
    Dor::Item.stub(:find).and_return(@item)
  end
  describe 'rights_list' do
    it 'should show stanford as the default' do
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

      pid='abc123'
      @item=double(Dor::Item)
      xml=Nokogiri::XML(content)
      Dor.stub(:find).and_return(@item)
      #using content metadata, but any datastream would do
      object_rights=double(Dor::ContentMetadataDS)
      object_rights.stub(:ng_xml).and_return xml
      @item.stub(:defaultObjectRights).and_return object_rights
      get 'rights_list', :apo_id => 'abc', :format => :xml
      expect(response.body.include?("Stanford (APO default)")).to eq(true)

    end
    it 'should show world as the default' do
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

      pid='abc123'
      @item=double(Dor::Item)
      xml=Nokogiri::XML(content)
      Dor.stub(:find).and_return(@item)
      #using content metadata, but any datastream would do
      object_rights=double(Dor::ContentMetadataDS)
      object_rights.stub(:ng_xml).and_return xml
      @item.stub(:defaultObjectRights).and_return object_rights
      get 'rights_list', :apo_id => 'abc', :format => :xml
      expect(response.body.include?("World (APO default)")).to eq(true)

    end
    it 'should show Dark if discover is none' do
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

      pid='abc123'
      @item=double(Dor::Item)
      xml=Nokogiri::XML(content)
      Dor.stub(:find).and_return(@item)
      #using content metadata, but any datastream would do
      object_rights=double(Dor::ContentMetadataDS)
      object_rights.stub(:ng_xml).and_return xml
      @item.stub(:defaultObjectRights).and_return object_rights
      get 'rights_list', :apo_id => 'abc', :format => :xml
      expect(response.body.include?("Dark (APO default)")).to eq(true)

    end
    it 'should show Dark as the default' do
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

      pid='abc123'
      @item=double(Dor::Item)
      xml=Nokogiri::XML(content)
      Dor.stub(:find).and_return(@item)
      #using content metadata, but any datastream would do
      object_rights=double(Dor::ContentMetadataDS)
      object_rights.stub(:ng_xml).and_return xml
      @item.stub(:defaultObjectRights).and_return object_rights
      get 'rights_list', :apo_id => 'abc', :format => :xml
      expect(response.body.include?("Dark (APO default)")).to eq(true)

    end
    it 'should show no default if there is no xml' do
      content=''
      pid='abc123'
      @item=double(Dor::Item)
      xml=Nokogiri::XML(content)
      Dor.stub(:find).and_return(@item)
      #using content metadata, but any datastream would do
      object_rights=double(Dor::ContentMetadataDS)
      object_rights.stub(:ng_xml).and_return xml
      @item.stub(:defaultObjectRights).and_return object_rights
      get 'rights_list', :apo_id => 'abc', :format => :xml
      expect(response.body.include?("none (set in Assembly)")).to eq(true)
    end
  end
end
