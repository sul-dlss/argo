require 'spec_helper'
describe ApoController do

  before :each do
    ActiveFedora::Base.stub(:find) do |id, args|
      item = instantiate_fixture(id, Dor::AdminPolicyObject)
      item.stub(:save) unless item.nil?
      item.stub(:udpate_index) unless item.nil?
      item
    end
    @item = Dor::AdminPolicyObject.find("druid:zt570tx3016")
    @empty_item = Dor::AdminPolicyObject.find("pw570tx3016")
  # ItemsController.any_instance.stub(:current_user).and_return(@current_user)
    log_in_as_mock_user(subject)
  end
  
  describe 'create' do
    it 'should create an apo' do
    end
    example = {"title"=>"New APO Title", "agreement"=>"druid:xf765cv5573", "desc_md"=>"MODS", "metadata_source"=>"DOR", "managers"=>"dlss:developers dlss:dpg-staff", "viewers"=>"sdr:viewer-role , dlss:forensics-staff", "collection_radio"=>"", "collection_title"=>'col title', "collection_abstract"=>"", "default_object_rights"=>"World", "use"=>"", "copyright"=>"", "cc_license"=>"", "workflow"=>"digitizationWF", "register"=>""}

    it 'should hit the registration service to register an apo and a collection' do
      Dor::RegistrationService.should_receive(:create_from_request) do |params|
        expect(params[:label]          ).to eq('New APO Title')
        expect(params[:object_type]    ).to eq('adminPolicy')
        expect(params[:admin_policy]   ).to eq('druid:hv992ry2431')
        expect(params[:metadata_source]).to eq(nil) #descMD is created via the form
        {:pid => 'druid:collectionpid'}
      end
      @item.should_receive(:add_roleplayer).exactly(4).times
      Dor.should_receive(:find).with('druid:collectionpid').and_return(@item)
      post 'register', example
    end
    it 'should set apo workflows to priority 70' do
      Dor::RegistrationService.should_receive(:create_from_request) do |params|
        expect(params[:workflow_priority]).to eq('70')
        {:pid => 'druid:collectionpid'}
      end
      @item.should_receive(:add_roleplayer).exactly(4).times
      Dor.should_receive(:find).with('druid:collectionpid').and_return(@item)
      post 'register', example
    end
  end
  describe 'register_collection' do
    before :each do
      Dor.stub(:find).with('druid:forapo', :lightweight=>true).and_return(@empty_item)
      @empty_item.should_receive(:add_default_collection).with('druid:newcollection')
    end
    it 'should create a collection via catkey' do
      catkey='1234567'
      Dor::RegistrationService.should_receive(:create_from_request) do |params|
        expect(params[:label]          ).to eq(':auto')
        expect(params[:object_type]    ).to eq('collection')
        expect(params[:admin_policy]   ).to eq('druid:forapo')
        expect(params[:other_id]       ).to eq('symphony:'+catkey)
        expect(params[:metadata_source]).to eq('symphony')
        expect(params[:rights]         ).to eq("dark")
        {:pid => 'druid:newcollection'}
      end
      post "register_collection", "label"=>":auto", "collection_catkey"=>catkey, "collection_rights_catkey"=>"dark", 'id'=>'druid:forapo'
    end
    it 'should create a collection from title/abstract by registering the collection, then adding the abstract' do
      title='collection title'
      abstract='this is the abstract'
      Dor::RegistrationService.should_receive(:create_from_request) do |params|
        expect(params[:label]          ).to eq(title)
        expect(params[:object_type]    ).to eq('collection')
        expect(params[:admin_policy]   ).to eq('druid:forapo')
        expect(params[:metadata_source]).to eq('label')
        expect(params[:rights]         ).to eq('dark')
        {:pid => 'druid:newcollection'}
      end
    # col=double(Dor::Item)
      Dor.should_receive(:find).with('druid:newcollection').and_return(@item)
      @item.descMetadata.should_receive(:abstract=).with(abstract)
      @item.descMetadata.should_receive(:content=)
      post "register_collection", "collection_title"=>title,'collection_abstract'=>abstract , "collection_rights"=>"dark", 'id'=>'druid:forapo'
    end
    it 'should add the collection to the apo default collection list' do
      title='collection title'
      abstract='this is the abstract'
      Dor::RegistrationService.should_receive(:create_from_request) do |params|
        expect(params[:label]          ).to eq(title)
        expect(params[:object_type]    ).to eq('collection')
        expect(params[:admin_policy]   ).to eq('druid:forapo')
        expect(params[:metadata_source]).to eq('label')
        expect(params[:rights]         ).to eq('dark')
        {:pid => 'druid:newcollection'}
      end
      controller.should_receive(:set_abstract)
      post "register_collection", "collection_title"=>title,'collection_abstract'=>abstract , "collection_rights"=>"dark", 'id'=>'druid:forapo'
    end
    it 'should set the workflow priority to 65' do
      catkey='1234567'
      Dor::RegistrationService.should_receive(:create_from_request) do |params|
        expect(params[:workflow_priority]).to eq('65')
        {:pid => 'druid:newcollection'}
      end
      post "register_collection", "label"=>":auto", "collection_catkey"=>catkey, "collection_rights_catkey"=>"dark", 'id'=>'druid:forapo'
    end
  end

  describe 'add_roleplayer' do
    it 'adds a roleplayer' do
      Dor.should_receive(:find).and_return @item
      @item.should_receive(:add_roleplayer)
      post 'add_roleplayer', :id => 'druid_zt570tx3016', :role => 'dor-apo-viewer', :roleplayer => 'Jon'
    end
  end
  describe 'delete_role' do
    it 'calls delete_role' do
      Dor.should_receive(:find).and_return @item
      @item.should_receive(:delete_role)
      post 'delete_role', :id => 'druid_zt570tx3016', :role => 'dor-apo-viewer', :entity => 'Jon'
    end
  end
  describe 'delete_collection' do
    it 'calls remove_default_collection' do
      Dor.should_receive(:find).and_return @item
      @item.should_receive(:remove_default_collection)
      post 'delete_collection', :id => 'druid_zt570tx3016', :collection => 'druid:123'
    end
  end
  describe 'add_collection' do
    it 'calls add_default_collection' do
      Dor.should_receive(:find).and_return @item
      @item.should_receive(:add_default_collection)
      post 'add_collection', :id => 'druid_zt570tx3016', :collection => 'druid:123'
    end
  end
  describe 'update_title' do
    it 'calls set_title' do
      Dor.should_receive(:find).and_return @item
      @item.should_receive(:mods_title=)
      post 'update_title', :id => 'druid_zt570tx3016', :title => 'awesome new title'
    end
  end
  describe 'update_creative_commons' do
    it 'should call set_creative_commons' do
      Dor.should_receive(:find).and_return @item
      @item.should_receive(:creative_commons_license=)
      post 'update_creative_commons', :id => 'druid_zt570tx3016', :cc_license => 'cc_by'
    end
  end
  describe 'update_use' do
    it 'calls set_use_statement' do
      Dor.should_receive(:find).and_return @item
      @item.should_receive(:use_statement=)
      post 'update_use', :id => 'druid_zt570tx3016', :use => 'new use statement'
    end
  end
  describe 'update_copyight' do
    it 'calls set_copyright_statement' do
      Dor.should_receive(:find).and_return @item
      @item.should_receive(:copyright_statement=)
      post 'update_copyright', :id => 'druid_zt570tx3016', :copyright => 'new copyright statement'
    end
  end
  describe 'update_default_object_rights' do
    it 'calls set_default_rights' do
      Dor.should_receive(:find).and_return @item
      @item.should_receive(:default_rights=)
      post 'update_default_object_rights', :id => 'druid_zt570tx3016', :rights => 'stanford'
    end
  end
  describe 'update_desc_metadata' do
    it 'calls set_desc_metadata_format' do
      Dor.should_receive(:find).and_return @item
      @item.should_receive(:desc_metadata_format=)
      post 'update_desc_metadata', :id => 'druid_zt570tx3016', :desc_md => 'TEI'
    end
  end
end
