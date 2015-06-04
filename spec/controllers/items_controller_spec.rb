require 'spec_helper'
describe ItemsController, :type => :controller do
  before :each do
    # TODO: use fixtures here, this is too much stubbing
    @item = double(Dor::Item)
    allow(@item).to receive(:to_solr)
    @current_user=double(:webauth_user, :login => 'sunetid', :logged_in? => true,:privgroup=>ADMIN_GROUPS.first)
    allow(@current_user).to receive(:is_admin).and_return(true)
    allow(@current_user).to receive(:roles).and_return([])
    allow(@current_user).to receive(:is_manager).and_return(false)
    allow_any_instance_of(ItemsController).to receive(:current_user).and_return(@current_user)
    allow(Dor::Item).to receive(:find).with('druid:oo201oo0001').and_return(@item)
    @event_ds=double(Dor::EventsDS)
    allow(@event_ds).to receive(:add_event)
    @ds={}
    idmd=double()
    allow(idmd).to receive(:dirty=)
    allow(@item).to receive(:save)
    @ds['identityMetadata']=idmd
    allow(@item).to receive(:identityMetadata).and_return(idmd)
    @ds['events'] = @event_ds
    allow(@item).to receive(:datastreams).and_return(@ds)
    allow(@item).to receive(:allows_modification?).and_return(true)
    allow(@item).to receive(:can_manage_item?    ).and_return(false)
    allow(@item).to receive(:can_manage_content? ).and_return(false)
    allow(@item).to receive(:can_view_content?   ).and_return(false)
    allow(@item).to receive(:pid).and_return('object:pid')
    allow(@item).to receive(:delete)
    @apo=double()
    allow(@apo).to receive(:pid).and_return('druid:apo')
    allow(@item).to receive(:admin_policy_object).and_return(@apo)
    wf=double()
    allow(wf).to receive(:content).and_return '<workflows objectId="druid:bx756pk3634"></workflows>'
    allow(@item).to receive(:workflows).and_return wf
    allow(Dor::SearchService.solr).to receive(:add)
    @pid='druid:oo201oo0001'
  end

  describe 'datastream_update' do
    it 'should allow a non admin to update the datastream' do
      allow(@item).to receive(:can_manage_content?).and_return(true)
      allow(@item).to receive(:can_manage_desc_metadata?).and_return(true)
      xml="<some> xml</some>"
      allow(@item.datastreams['identityMetadata']).to receive(:content=)
      post :datastream_update, :id => @pid, :dsid => 'identityMetadata', :content => xml
      expect(response.code).to eq("302")
    end
  end

  describe 'release_hold' do
    it 'should release an item that is on hold if its apo has been ingested' do
      expect(Dor::WorkflowService).to receive(:get_workflow_status).with('dor', 'object:pid', 'accessionWF','sdr-ingest-transfer').and_return('hold')
      expect(Dor::WorkflowService).to receive(:get_lifecycle).with('dor', 'druid:apo', 'accessioned').and_return(true)
      expect(Dor::WorkflowService).to receive(:update_workflow_status)
      post :release_hold, :id => @pid
    end
    it 'should refuse to release an item that isnt on hold' do
      expect(Dor::WorkflowService).to receive(:get_workflow_status).with('dor', 'object:pid', 'accessionWF','sdr-ingest-transfer').and_return('waiting')
      expect(Dor::WorkflowService).not_to receive(:update_workflow_status)
      post :release_hold, :id => @pid
    end
    it 'should refuse to release an item whose apo hasnt been ingested' do
      expect(Dor::WorkflowService).to receive(:get_workflow_status).with('dor', 'object:pid', 'accessionWF','sdr-ingest-transfer').and_return('hold')
      expect(Dor::WorkflowService).to receive(:get_lifecycle).with('dor', 'druid:apo', 'accessioned').and_return(false)
      expect(Dor::WorkflowService).not_to receive(:update_workflow_status)
      post :release_hold, :id => @pid
    end
  end
  describe 'purge' do
    it 'should 403' do
      allow(@current_user).to receive(:is_admin).and_return(false)
      post 'purge_object', :id => @pid
      expect(response.code).to eq("403")
    end
  end
  describe "embargo_update" do
    it "should 403 if you arent an admin" do
      allow(@current_user).to receive(:is_admin).and_return(false)
      post 'embargo_update', :id => @pid, :date => "12/19/2013"
      expect(response.code).to eq("403")
    end
    it "should call Dor::Item.update_embargo" do
      runs=0
      allow(@item).to receive(:update_embargo) do |a|
        runs=1
        true
      end
      post :embargo_update, :id => @pid,:embargo_date => "2012-10-19T00:00:00Z"
      expect(response.code).to eq("302")
      expect(runs).to eq(1)
    end
  end
  describe "register" do
    it "should load the registration form" do
      get :register
      expect(response).to render_template('register')
    end
  end
  describe "open_version" do
    it 'should call dor-services to open a new version' do
      allow(@item).to receive(:open_new_version)
      vers_md_upd_info = {:significance => 'major', :description => 'something', :opening_user_name => @current_user.to_s}
      expect(@item).to receive(:open_new_version).with({:vers_md_upd_info => vers_md_upd_info})
      expect(@item).to receive(:save)
      expect(Dor::SearchService.solr).to receive(:add)
      get 'open_version', :id => @pid, :severity => vers_md_upd_info[:significance], :description => vers_md_upd_info[:description]
    end
    it 'should 403 if you arent an admin' do
      allow(@current_user).to receive(:is_admin).and_return(false)
      get 'open_version', :id => @pid, :severity => 'major', :description => 'something'
      expect(response.code).to eq("403")
    end
  end
  describe "close_version" do
    it 'should call dor-services to close the version' do
      ran=false
      allow(@item).to receive(:close_version)do
        ran=true
      end
      version_metadata=double(Dor::VersionMetadataDS)
      allow(version_metadata).to receive(:current_version_id).and_return(2)
      allow(@item).to receive(:versionMetadata).and_return(version_metadata)
      expect(version_metadata).to receive(:update_current_version)
      allow(@item).to receive(:current_version).and_return('2')
      expect(@item).to receive(:save)
      expect(Dor::SearchService.solr).to receive(:add)
      get 'close_version', :id => @pid, :severity => 'major', :description => 'something'
      expect(ran).to eq(true)
    end
    it 'should 403 if you arent an admin' do
      allow(@current_user).to receive(:is_admin).and_return(false)
      get 'close_version', :id => @pid
      expect(response.code).to eq("403")
    end
  end
  describe "source_id" do
    it 'should update the source id' do
      expect(@item).to receive(:set_source_id).with('new:source_id')
      expect(Dor::SearchService.solr).to receive(:add)
      post 'source_id', :id => @pid, :new_id => 'new:source_id'
    end
  end
  describe "tags" do
    before :each do
      allow(@item).to receive(:tags).and_return(['some:thing'])
      expect(Dor::SearchService.solr).to receive(:add)
    end
    it 'should update tags' do
      expect(@item).to receive(:update_tag).with('some:thing', 'some:thingelse')
      post 'tags', :id => @pid, :update=>'true', :tag1 => 'some:thingelse'
    end
    it 'should delete tag' do
      expect(@item).to receive(:remove_tag).with('some:thing').and_return(true)
      post 'tags', :id => @pid, :tag => '1', :del => 'true'
    end
    it 'should add a tag' do
      expect(@item).to receive(:add_tag).with('new:thing')
      post 'tags', :id => @pid, :new_tag1 => 'new:thing', :add => 'true'
    end
  end
  describe 'tags_bulk' do
    before :each do
      allow(@item).to receive(:tags).and_return(['some:thing'])
      expect(@item.datastreams['identityMetadata']).to receive(:save)
      expect(Dor::SearchService.solr).to receive(:add)
    end
    it 'should remove an old tag an add a new one' do
      expect(@item).to receive(:remove_tag).with('some:thing').and_return(true)
      expect(@item).to receive(:add_tag).with('new:thing').and_return(true)
      post 'tags_bulk', :id => @pid, :tags => 'new:thing'
    end
    it 'should add multiple tags' do
      expect(@item).to receive(:add_tag).twice
      expect(@item).to receive(:remove_tag).with('some:thing').and_return(true)
      expect(@item).to receive(:save)
      post 'tags_bulk', :id => @pid, :tags => 'Process : Content Type : Book (flipbook, ltr)	 Registered By : labware'
    end
  end
  describe "set_rights" do
    it 'should set an item to dark' do
      expect(@item).to receive(:set_read_rights).with('dark')
      get 'set_rights', :id => @pid, :rights => 'dark'
    end
  end

  describe "add_file" do
    it 'should recieve an uploaded file and add it to the requested resource' do
      #found the UploadedFile approach at: http://stackoverflow.com/questions/7280204/rails-post-command-in-rspec-controllers-files-arent-passing-through-is-the
      file = Rack::Test::UploadedFile.new('spec/fixtures/cerenkov_radiation_160.jpg', 'image/jpg')
      ran=false
      allow(@item).to receive(:add_file) do
        ran=true
      end
      post 'add_file', :uploaded_file => file, :id => @pid, :resource => 'resourceID'
      expect(ran).to eq(true)
    end
    it 'should 403 if you are not an admin' do
      allow(@current_user).to receive(:is_admin).and_return(false)
      post 'add_file', :uploaded_file => nil, :id => @pid, :resource => 'resourceID'
      expect(response.code).to eq("403")
    end
  end
  describe "delete_file" do
    it 'should call dor services to remove the file' do
      ran=false
      allow(@item).to receive(:remove_file)do
        ran=true
      end
      get 'delete_file', :id => @pid, :file_name => 'old_file'
      expect(ran).to eq(true)
    end
    it 'should 403 if you arent an admin' do
      allow(@current_user).to receive(:is_admin).and_return(false)
      get 'delete_file', :id => @pid, :file_name => 'old_file'
      expect(response.code).to eq("403")
    end
  end
  describe "replace_file" do
    it 'should recieve an uploaded file and call dor-services' do
      #found the UploadedFile approach at: http://stackoverflow.com/questions/7280204/rails-post-command-in-rspec-controllers-files-arent-passing-through-is-the
      file = Rack::Test::UploadedFile.new('spec/fixtures/cerenkov_radiation_160.jpg', 'image/jpg')
      ran=false
      allow(@item).to receive(:replace_file) do
        ran=true
      end
      post 'replace_file', :uploaded_file => file, :id => @pid, :resource => 'resourceID', :file_name => 'somefile.txt'
      expect(ran).to eq(true)
    end
    it 'should 403 if you arent an admin' do
      allow(@current_user).to receive(:is_admin).and_return(false)
      post 'replace_file', :uploaded_file => nil, :id => @pid, :resource => 'resourceID', :file_name => 'somefile.txt'
      expect(response.code).to eq("403")
    end
  end
  describe "update_parameters" do
    it 'should update the shelve, publish and preserve to yes (used to be true)' do
      contentMD=double(Dor::ContentMetadataDS)
      allow(@item).to receive(:contentMetadata).and_return(contentMD)
      allow(contentMD).to receive(:update_attributes) do |file, publish, shelve, preserve|
        expect(shelve  ).to eq("yes")
        expect(preserve).to eq("yes")
        expect(publish ).to eq("yes")
      end
      post 'update_attributes', :shelve => 'on', :publish => 'on', :preserve => 'on', :id => @pid, :file_name => 'something.txt'
    end
    it 'should work ok if not all of the values are set' do
      contentMD=double(Dor::ContentMetadataDS)
      allow(@item).to receive(:contentMetadata).and_return(contentMD)
      allow(contentMD).to receive(:update_attributes) do |file, publish, shelve, preserve|
        expect(shelve  ).to eq("no")
        expect(preserve).to eq("yes")
        expect(publish ).to eq("yes")
      end
      post 'update_attributes',  :publish => 'on', :preserve => 'on', :id => @pid, :file_name => 'something.txt'
    end
    it 'should update the shelve, publish and preserve to no (used to be false)' do
      contentMD=double(Dor::ContentMetadataDS)
      allow(@item).to receive(:contentMetadata).and_return(contentMD)
      allow(contentMD).to receive(:update_attributes) do |file, publish, shelve, preserve|
        expect(shelve  ).to eq("no")
        expect(preserve).to eq("no")
        expect(publish ).to eq("no")
      end
      expect(contentMD).to receive(:update_attributes)
      post 'update_attributes', :shelve => 'no', :publish => 'no', :preserve => 'no', :id => @pid, :file_name => 'something.txt'
    end
    it 'should 403 if you arent an admin' do
      allow(@current_user).to receive(:is_admin).and_return(false)
      post 'update_attributes', :shelve => 'no', :publish => 'no', :preserve => 'no', :id => @pid, :file_name => 'something.txt'
      expect(response.code).to eq("403")
    end
  end
  describe 'get_file' do
    it 'should have dor-services fetch a file from the workspace' do
      allow(@item).to receive(:get_file).and_return('abc')
      expect(@item).to receive(:get_file)
      get 'get_file', :file => 'somefile.txt', :id => @pid
    end
    it 'should 403 if you arent an admin' do
      allow(@current_user).to receive(:is_admin).and_return(false)
      get 'get_file', :file => 'somefile.txt', :id => @pid
      expect(response.code).to eq("403")
    end
  end
  describe 'datastream_update' do
    it 'should 403 if you arent an admin' do
      allow(@current_user).to receive(:is_admin).and_return(false)
      post 'datastream_update', :dsid => 'contentMetadata', :id => @pid, :content => '<contentMetadata/>'
      expect(response.code).to eq("403")
    end
    it 'should error on malformed xml' do
      expect(lambda {post 'datastream_update', :dsid => 'contentMetadata', :id => @pid, :content => '<this>isnt well formed.'}).to raise_error() # TODO: add name of error
    end
    it 'should call save with good xml' do
      mock_ds=double(Dor::ContentMetadataDS)
      allow(mock_ds).to receive(:content=)
      expect(@item).to receive(:save)
      allow(@item).to receive(:datastreams).and_return({'contentMetadata' => mock_ds})
      allow(mock_ds).to receive(:dirty?).and_return(false)
      post 'datastream_update', :dsid => 'contentMetadata', :id => @pid, :content => '<contentMetadata><text>hello world</text></contentMetadata>'
    end
  end
  describe 'update_sequence' do
    before :each do
      @mock_ds=double(Dor::ContentMetadataDS)
      allow(@mock_ds).to receive(:dirty?).and_return(false)
      allow(@mock_ds).to receive(:save)
      allow(@item).to receive(:datastreams).and_return({'contentMetadata' => @mock_ds})
    end
    it 'should 403 if you are not an admin' do
      allow(@current_user).to receive(:is_admin).and_return(false)
      post 'update_resource', :resource => '0001', :position => '3', :id => @pid
      expect(response.code).to eq("403")
    end
    it 'should call dor-services to reorder the resources' do
      expect(@item).to receive(:move_resource)
      post 'update_resource', :resource => '0001', :position => '3', :id => @pid
    end
    it 'should call dor-services to change the label' do
      expect(@item).to receive(:update_resource_label)
      post 'update_resource', :resource => '0001', :label => 'label!', :id => @pid
    end
    it 'should call dor-services to update the resource type' do
      expect(@item).to receive(:update_resource_type)
      post 'update_resource', :resource => '0001', :type => 'book', :id => @pid
    end
  end
  describe 'resource' do
    it 'should set the object and datastream, then call the view' do
      expect(Dor::Item).to receive(:find)
      mock_ds=double(Dor::ContentMetadataDS)
      allow(@item).to receive(:datastreams).and_return({'contentMetadata' => mock_ds})
      get 'resource', :id => @pid, :resource => '0001'
    end
  end
  describe 'add_collection' do
    it 'should add a collection' do
      expect(@item).to receive(:add_collection).with('druid:1234')
      post 'add_collection', :id => @pid, :collection => 'druid:1234'
    end
    it 'should 403 if they arent permitted' do
      allow(@current_user).to receive(:is_admin).and_return(false)
      post 'add_collection', :id => @pid, :collection => 'druid:1234'
      expect(response.code).to eq("403")
    end
  end
  describe 'set_collection' do
    it 'should add a collection if there is none yet' do
      collection_druid = 'druid:1234'
      allow(@item).to receive(:collections).and_return([])
      expect(@item).to receive(:add_collection).with(collection_druid)
      post 'set_collection', :id => @pid, :collection => collection_druid, :bulk => true
      expect(response.code).to eq("200")
    end
    it 'should not add a collection if there is already one' do
      collection_druid = 'druid:1234'
      allow(@item).to receive(:collections).and_return(['collection'])
      expect(@item).not_to receive(:add_collection)
      post 'set_collection', :id => @pid, :collection => collection_druid, :bulk => true
      expect(response.code).to eq("500")
    end
  end
  describe 'remove_collection' do
    it 'should remove a collection' do
      expect(@item).to receive(:remove_collection).with('druid:1234')
      post 'remove_collection', :id => @pid, :collection => 'druid:1234'
    end
    it 'should 403 if they arent permitted' do
      allow(@current_user).to receive(:is_admin).and_return(false)
      post 'remove_collection', :id => @pid, :collection => 'druid:1234'
      expect(response.code).to eq("403")
    end
  end
  describe 'mods' do
    it 'should return the mods xml for a GET' do
      @request.env["HTTP_ACCEPT"] = "application/xml"
      xml='<somexml>stuff</somexml>'
      descmd=double()
      expect(descmd).to receive(:content).and_return(xml)
      expect(@item).to receive(:descMetadata).and_return(descmd)
      get 'mods', :id => @pid
      expect(response.body).to eq(xml)
    end
    it 'should 403 if they arent permitted' do
      allow(@current_user).to receive(:is_admin).and_return(false)
      get 'mods', :id => @pid
      expect(response.code).to eq("403")
    end
  end
  describe 'update_mods' do
    it 'should update the mods for a POST' do
      xml = '<somexml>stuff</somexml>'
      descmd = double()
      expect(@item).to receive(:descMetadata).and_return(descmd).exactly(2).times
      expect(descmd).to receive(:content=).with(xml)
      expect(descmd).to receive(:ng_xml).and_return(xml)
      post 'update_mods', :id => @pid, :xmlstr => xml, :format => 'xml'
      expect(response.body).to eq(xml)
    end
    it 'should 403 if they arent permitted' do
      allow(@current_user).to receive(:is_admin).and_return(false)
      get 'update_mods', :id => @pid
      expect(response.code).to eq("403")
    end
  end
  describe "add_workflow" do
    before :each do
      @wf=double()
      @mock_wf=double()
      expect(@item).to receive(:workflows).and_return @wf
    end
    it 'should initialize the new workflow' do
      expect(@item).to receive(:initialize_workflow)
      expect(@wf).to receive(:[]).and_return(nil)
      post 'add_workflow', :id => @pid, :wf => 'accessionWF'
    end
    it 'shouldnt initialize the workflow if one is already active' do
      expect(@item).not_to receive(:initialize_workflow)
      expect(@mock_wf).to receive(:active?).and_return(true)
      expect(@wf).to receive(:[]).and_return(@mock_wf)
      post 'add_workflow', :id => @pid, :wf => 'accessionWF'
    end
  end
end
