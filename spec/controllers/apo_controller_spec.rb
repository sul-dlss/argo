require 'spec_helper'
describe ApoController, :type => :controller do

  before :each do
    allow(ActiveFedora::Base).to receive(:find) do |id, args|
      item = instantiate_fixture(id, Dor::AdminPolicyObject)
      allow(item).to receive(:save) unless item.nil?
      allow(item).to receive(:udpate_index) unless item.nil?
      item
    end
    @item = Dor::AdminPolicyObject.find("druid:zt570tx3016")
    @empty_item = Dor::AdminPolicyObject.find("pw570tx3016")
  # ItemsController.any_instance.stub(:current_user).and_return(@current_user)
    log_in_as_mock_user(subject)
  end

  describe 'create' do
    before :each do
      @example = {"title"=>"New APO Title", "agreement"=>"druid:xf765cv5573", "desc_md"=>"MODS", "metadata_source"=>"DOR",
              "managers"=>"dlss:developers dlss:dpg-staff", "viewers"=>"sdr:viewer-role , dlss:forensics-staff", "collection_radio"=>"",
              "collection_title"=>'col title', "collection_abstract"=>"", "default_object_rights"=>"World", "use"=>"", "copyright"=>"",
              "cc_license"=>"", "workflow"=>"registrationWF", "register"=>""}
      # block cascading update
      allow(controller).to receive(:update_index)
      expect(@item).to receive(:add_roleplayer).exactly(4).times
      expect(Dor).to receive(:find).with('druid:collectionpid').and_return(@item)
    end

    it 'should create an apo' do
      skip "Unimplemented"
    end
    ## FIXME: The next two tests still hit solr looking for druid:dd327qr3670.
    ## They should be stubbed/contained.
    it 'should hit the registration service to register an apo and a collection' do
      expect(Dor::RegistrationService).to receive(:create_from_request) do |params|
        expect(params).to match a_hash_including(:label => 'New APO Title', :object_type => 'adminPolicy', :admin_policy => 'druid:hv992ry2431')
        expect(params[:metadata_source]).to be_nil   #descMD is created via the form
        {:pid => 'druid:collectionpid'}
      end
      post 'register', @example
    end
    it 'should set apo workflows to priority 70' do
      expect(Dor::RegistrationService).to receive(:create_from_request) do |params|
        expect(params[:workflow_priority]).to eq('70')
        {:pid => 'druid:collectionpid'}
      end
      post 'register', @example
    end
  end

  describe 'register_collection' do
    before :each do
      allow(Dor).to receive(:find).with('druid:forapo', :lightweight=>true).and_return(@empty_item)
      expect(@empty_item).to receive(:add_default_collection).with('druid:newcollection')
      @new_collection_druid = 'druid:newcollection'
      @mock_new_collection = double(Dor::Collection)
      expect(Dor).to receive(:find).with(@new_collection_druid).and_return(@mock_new_collection)
    end

    it 'should create a collection via catkey' do
      catkey = '1234567'
      expect(Dor::RegistrationService).to receive(:create_from_request) do |params|
        expect(params).to match a_hash_including(
          :label           => ':auto',
          :object_type     => 'collection',
          :admin_policy    => 'druid:forapo',
          :other_id        => 'symphony:'+catkey,
          :metadata_source => 'symphony',
          :rights          => 'dark'
        )
        {:pid => @new_collection_druid}
      end
      expect(@mock_new_collection).to receive(:save)
      expect(@mock_new_collection).to receive(:update_index)
      post "register_collection", "label"=>":auto", "collection_catkey"=>catkey, "collection_rights_catkey"=>"dark", 'id'=>'druid:forapo'
    end

    it 'should create a collection from title/abstract by registering the collection, then adding the abstract' do
      title='collection title'
      abstract='this is the abstract'
      mock_desc_md_ds = double(Dor::DescMetadataDS)

      expect(Dor::RegistrationService).to receive(:create_from_request) do |params|
        expect(params).to match a_hash_including(
          :label           => title,
          :object_type     => 'collection',
          :admin_policy    => 'druid:forapo',
          :metadata_source => 'label',
          :rights          => 'dark'
        )
        {:pid => @new_collection_druid}
      end
      expect(@mock_new_collection).to receive(:descMetadata).and_return(mock_desc_md_ds).exactly(4).times
      expect(mock_desc_md_ds).to receive(:abstract=).with(abstract)
      expect(mock_desc_md_ds).to receive(:ng_xml)
      expect(mock_desc_md_ds).to receive(:content=)
      expect(mock_desc_md_ds).to receive(:save)
      expect(@mock_new_collection).to receive(:save)
      expect(@mock_new_collection).to receive(:update_index)

      post "register_collection", "collection_title"=>title,'collection_abstract'=>abstract, "collection_rights"=>"dark", 'id'=>'druid:forapo'
    end

    it 'should add the collection to the apo default collection list' do
      title='collection title'
      abstract='this is the abstract'
      expect(Dor::RegistrationService).to receive(:create_from_request) do |params|
        expect(params).to match a_hash_including(
          :label           => title,
          :object_type     => 'collection',
          :admin_policy    => 'druid:forapo',
          :metadata_source => 'label',
          :rights          => 'dark'
        )
        {:pid => @new_collection_druid}
      end
      expect(controller).to receive(:set_abstract)
      expect(@mock_new_collection).to receive(:save)
      expect(@mock_new_collection).to receive(:update_index)

      post "register_collection", "collection_title"=>title,'collection_abstract'=>abstract, "collection_rights"=>"dark", 'id'=>'druid:forapo'
    end
    it 'should set the workflow priority to 65' do
      catkey='1234567'
      expect(Dor::RegistrationService).to receive(:create_from_request) do |params|
        expect(params[:workflow_priority]).to eq('65')
        {:pid => @new_collection_druid}
      end
      expect(@mock_new_collection).to receive(:save)
      expect(@mock_new_collection).to receive(:update_index)
      post "register_collection", "label"=>":auto", "collection_catkey"=>catkey, "collection_rights_catkey"=>"dark", 'id'=>'druid:forapo'
    end
  end

  describe 'overly literal tests' do
    before :each do
      expect(Dor).to receive(:find).and_return @item
    end
    describe 'add_roleplayer' do
      it 'adds a roleplayer' do
        expect(@item).to receive(:add_roleplayer)
        post 'add_roleplayer', :id => 'druid_zt570tx3016', :role => 'dor-apo-viewer', :roleplayer => 'Jon'
      end
    end
    describe 'delete_role' do
      it 'calls delete_role' do
        expect(@item).to receive(:delete_role)
        post 'delete_role', :id => 'druid_zt570tx3016', :role => 'dor-apo-viewer', :entity => 'Jon'
      end
    end
    describe 'delete_collection' do
      it 'calls remove_default_collection' do
        expect(@item).to receive(:remove_default_collection)
        post 'delete_collection', :id => 'druid_zt570tx3016', :collection => 'druid:123'
      end
    end
    describe 'add_collection' do
      it 'calls add_default_collection' do
        expect(@item).to receive(:add_default_collection)
        post 'add_collection', :id => 'druid_zt570tx3016', :collection => 'druid:123'
      end
    end
    describe 'update_title' do
      it 'calls set_title' do
        expect(@item).to receive(:mods_title=)
        post 'update_title', :id => 'druid_zt570tx3016', :title => 'awesome new title'
      end
    end
    describe 'update_creative_commons' do
      it 'should set creative_commons' do
        expect(@item).to receive(:creative_commons_license=)
        expect(@item).to receive(:creative_commons_license_human=)
        post 'update_creative_commons', :id => 'druid_zt570tx3016', :cc_license => 'by-nc'
      end
    end
    describe 'update_use' do
      it 'calls set_use_statement' do
        expect(@item).to receive(:use_statement=)
        post 'update_use', :id => 'druid_zt570tx3016', :use => 'new use statement'
      end
    end
    describe 'update_copyight' do
      it 'calls set_copyright_statement' do
        expect(@item).to receive(:copyright_statement=)
        post 'update_copyright', :id => 'druid_zt570tx3016', :copyright => 'new copyright statement'
      end
    end
    describe 'update_default_object_rights' do
      it 'calls set_default_rights' do
        expect(@item).to receive(:default_rights=)
        post 'update_default_object_rights', :id => 'druid_zt570tx3016', :rights => 'stanford'
      end
    end
    describe 'update_desc_metadata' do
      it 'calls set_desc_metadata_format' do
        expect(@item).to receive(:desc_metadata_format=)
        post 'update_desc_metadata', :id => 'druid_zt570tx3016', :desc_md => 'TEI'
      end
    end
  end
end
