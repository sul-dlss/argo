require 'spec_helper'
describe ItemsController, :type => :controller do
  before :each do
    @pid  = 'druid:oo201oo0001'
    @item = Dor::Item.new pid: @pid
    @current_user = User.find_or_create_by_webauth(
      double(
        'webauth',
        :login => 'sunetid',
        :attributes => { 'DISPLAYNAME' => 'Rando User'},
        :logged_in? => true,
        :privgroup => User::ADMIN_GROUPS.first
      )
    )
    allow(@current_user).to receive(:is_admin?).and_return(true)
    allow(@current_user).to receive(:is_manager?).and_return(false)
    allow(@current_user).to receive(:roles).and_return([])
    allow_any_instance_of(ItemsController).to receive(:current_user).and_return(@current_user)
    allow(Dor::Item).to receive(:find).with(@pid).and_return(@item)
    idmd = double()
    apo  = double()
    wf   = double()
    idmd_ds_content = '<test-xml/>'
    idmd_ng_xml = double(Nokogiri::XML::Document)
    allow(idmd).to receive(:"content_will_change!")
    allow(idmd_ng_xml).to receive(:to_xml).and_return idmd_ds_content
    allow(idmd).to receive(:ng_xml).and_return idmd_ng_xml
    allow(idmd).to receive(:"content=").with(idmd_ds_content)
    allow(apo).to receive(:pid).and_return('druid:apo')
    allow(wf).to receive(:content).and_return '<workflows objectId="druid:bx756pk3634"></workflows>'
    allow(@item).to receive(:to_solr)
    allow(@item).to receive(:save)
    allow(@item).to receive(:delete)
    allow(@item).to receive(:identityMetadata).and_return(idmd)
    allow(@item).to receive(:datastreams).and_return({'identityMetadata' => idmd, 'events' => Dor::EventsDS.new})
    allow(@item).to receive(:allows_modification?).and_return(true)
    allow(@item).to receive(:can_manage_item?    ).and_return(false)
    allow(@item).to receive(:can_manage_content? ).and_return(false)
    allow(@item).to receive(:can_view_content?   ).and_return(false)
    allow(@item).to receive(:pid).and_return('object:pid')
    allow(@item).to receive(:admin_policy_object).and_return(apo)
    allow(@item).to receive(:workflows).and_return(wf)
    allow(Dor::SearchService.solr).to receive(:add)
  end

  describe 'release_hold' do
    it 'should release an item that is on hold if its apo has been ingested' do
      expect(Dor::Config.workflow.client).to receive(:get_workflow_status).with('dor', 'object:pid', 'accessionWF', 'sdr-ingest-transfer').and_return('hold')
      expect(Dor::Config.workflow.client).to receive(:get_lifecycle).with('dor', 'druid:apo', 'accessioned').and_return(true)
      expect(Dor::Config.workflow.client).to receive(:update_workflow_status)
      post :release_hold, :id => @pid
    end
    it 'should refuse to release an item that isnt on hold' do
      expect(Dor::Config.workflow.client).to receive(:get_workflow_status).with('dor', 'object:pid', 'accessionWF', 'sdr-ingest-transfer').and_return('waiting')
      expect(Dor::Config.workflow.client).not_to receive(:update_workflow_status)
      post :release_hold, :id => @pid
    end
    it 'should refuse to release an item whose apo hasnt been ingested' do
      expect(Dor::Config.workflow.client).to receive(:get_workflow_status).with('dor', 'object:pid', 'accessionWF', 'sdr-ingest-transfer').and_return('hold')
      expect(Dor::Config.workflow.client).to receive(:get_lifecycle).with('dor', 'druid:apo', 'accessioned').and_return(false)
      expect(Dor::Config.workflow.client).not_to receive(:update_workflow_status)
      post :release_hold, :id => @pid
    end
  end
  describe 'purge' do
    it 'should 403' do
      allow(@current_user).to receive(:is_admin?).and_return(false)
      post 'purge_object', :id => @pid
      expect(response.code).to eq('403')
    end
  end
  describe 'embargo_update' do
    it 'should 403 if you are not an admin' do
      expect(@current_user).to receive(:is_admin?).and_return(false)
      expect(subject).not_to receive(:save_and_reindex)
      expect(subject).not_to receive(:flush_index)
      post :embargo_update, :id => @pid, :embargo_date => '2100-01-01'
      expect(response).to have_http_status(:forbidden)
    end
    it 'should call Dor::Item.update_embargo' do
      expect(@item).to receive(:update_embargo)
      expect(@item.datastreams['events']).to receive(:add_event).and_call_original
      expect(controller).to receive(:save_and_reindex)
      expect(controller).to receive(:flush_index).and_call_original
      expect(Dor::SearchService.solr).to receive(:commit) # from flush_index internals
      post :embargo_update, :id => @pid, :embargo_date => '2100-01-01'
      expect(response).to have_http_status(:found) # redirect to catalog page
    end
    it 'should require a date' do
      expect { post :embargo_update, :id => @pid }.to raise_error(ArgumentError)
    end
    it 'should die on a malformed date' do
      expect { post :embargo_update, :id => @pid, :embargo_date => 'not-a-date' }.to raise_error(ArgumentError)
    end
  end
  describe 'register' do
    it 'should load the registration form' do
      get :register
      expect(response).to render_template('register')
    end
  end
  describe 'open_version' do
    it 'should call dor-services to open a new version' do
      allow(@item).to receive(:open_new_version)
      vers_md_upd_info = {:significance => 'major', :description => 'something', :opening_user_name => @current_user.to_s}
      expect(@item).to receive(:open_new_version).with({:vers_md_upd_info => vers_md_upd_info})
      expect(@item).to receive(:save)
      expect(Dor::SearchService.solr).to receive(:add)
      get 'open_version', :id => @pid, :severity => vers_md_upd_info[:significance], :description => vers_md_upd_info[:description]
    end
    it 'should 403 if you are not an admin' do
      allow(@current_user).to receive(:is_admin?).and_return(false)
      get 'open_version', :id => @pid, :severity => 'major', :description => 'something'
      expect(response.code).to eq('403')
    end
  end
  describe 'close_version' do
    it 'should call dor-services to close the version' do
      expect(@item).to receive(:close_version)
      version_metadata = double(Dor::VersionMetadataDS)
      allow(version_metadata).to receive(:current_version_id).and_return(2)
      allow(@item).to receive(:versionMetadata).and_return(version_metadata)
      expect(version_metadata).to receive(:update_current_version)
      allow(@item).to receive(:current_version).and_return('2')
      expect(@item).to receive(:save)
      expect(Dor::SearchService.solr).to receive(:add)
      get 'close_version', :id => @pid, :severity => 'major', :description => 'something'
    end
    it 'should 403 if you are not an admin' do
      allow(@current_user).to receive(:is_admin?).and_return(false)
      get 'close_version', :id => @pid
      expect(response.code).to eq('403')
    end
  end
  describe 'source_id' do
    it 'should update the source id' do
      expect(@item).to receive(:set_source_id).with('new:source_id')
      expect(Dor::SearchService.solr).to receive(:add)
      post 'source_id', :id => @pid, :new_id => 'new:source_id'
    end
  end
  describe 'tags' do
    before :each do
      allow(@item).to receive(:tags).and_return(['some:thing'])
      expect(Dor::SearchService.solr).to receive(:add)
    end
    it 'should update tags' do
      expect(@item).to receive(:update_tag).with('some:thing', 'some:thingelse')
      post 'tags', :id => @pid, :update => 'true', :tag1 => 'some:thingelse'
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
  describe 'set_rights' do
    it 'should set an item to dark' do
      expect(@item).to receive(:set_read_rights).with('dark')
      get 'set_rights', :id => @pid, :rights => 'dark'
    end
  end
  describe 'update_parameters' do
    before :each do
      @content_md = double(Dor::ContentMetadataDS)
      allow(@item).to receive(:contentMetadata).and_return(@content_md)
    end
    it 'should update the shelve, publish and preserve to yes (used to be true)' do
      allow(@content_md).to receive(:update_attributes) do |file, publish, shelve, preserve|
        expect(shelve  ).to eq('yes')
        expect(preserve).to eq('yes')
        expect(publish ).to eq('yes')
      end
      post 'update_attributes', :shelve => 'on', :publish => 'on', :preserve => 'on', :id => @pid, :file_name => 'something.txt'
    end
    it 'should work ok if not all of the values are set' do
      allow(@content_md).to receive(:update_attributes) do |file, publish, shelve, preserve|
        expect(shelve  ).to eq('no')
        expect(preserve).to eq('yes')
        expect(publish ).to eq('yes')
      end
      post 'update_attributes', :publish => 'on', :preserve => 'on', :id => @pid, :file_name => 'something.txt'
    end
    it 'should update the shelve, publish and preserve to no (used to be false)' do
      allow(@content_md).to receive(:update_attributes) do |file, publish, shelve, preserve|
        expect(shelve  ).to eq('no')
        expect(preserve).to eq('no')
        expect(publish ).to eq('no')
      end
      expect(@content_md).to receive(:update_attributes)
      post 'update_attributes', :shelve => 'no', :publish => 'no', :preserve => 'no', :id => @pid, :file_name => 'something.txt'
    end
    it 'should 403 if you are not an admin' do
      allow(@current_user).to receive(:is_admin?).and_return(false)
      post 'update_attributes', :shelve => 'no', :publish => 'no', :preserve => 'no', :id => @pid, :file_name => 'something.txt'
      expect(response.code).to eq('403')
    end
  end
  describe 'get_file' do
    it 'should have dor-services fetch a file from the workspace' do
      allow(@item).to receive(:get_file).and_return('abc')
      expect(@item).to receive(:get_file)
      allow(Time).to receive(:now).and_return(Time.parse 'Mon, 30 Nov 2015 20:19:43 UTC')
      get 'get_file', :file => 'somefile.txt', :id => @pid
      expect(response.headers['Last-Modified']).to eq 'Mon, 30 Nov 2015 20:19:43 -0000'
    end
    it 'should 403 if you are not an admin' do
      allow(@current_user).to receive(:is_admin?).and_return(false)
      get 'get_file', :file => 'somefile.txt', :id => @pid
      expect(response.code).to eq('403')
    end
  end
  describe '#datastream_update' do
    let(:xml) { '<contentMetadata/>' }
    let(:invalid_apo_xml) { '<hydra:isGovernedBy rdf:resource="info:fedora/druid:not_exist"/>' }
    context 'save cases' do
      before :each do
        expect(@item).to receive(:datastreams).and_return({
          'contentMetadata' => double(Dor::ContentMetadataDS, :'content=' => xml)
        })
        expect(@item).to receive(:save)
      end
      it 'should allow an admin to update the datastream' do
        expect(@current_user).to receive(:is_admin?).and_return(true)
        post 'datastream_update', :dsid => 'contentMetadata', :id => @pid, :content => xml
        expect(response).to have_http_status(:found)
      end
      it 'should allow access if you are not an admin but have management access' do
        expect(@current_user).to receive(:is_admin?).and_return(false)
        expect(@item).to receive(:can_manage_content?).and_return(true)
        post 'datastream_update', :dsid => 'contentMetadata', :id => @pid, :content => xml
        expect(response).to have_http_status(:found)
      end
    end
    context 'error cases' do
      it 'should prevent access if you are not an admin and without management access' do
        expect(@current_user).to receive(:is_admin?).and_return(false)
        expect(@item).to receive(:can_manage_content?).and_return(false)
        expect(@item).not_to receive(:save)
        post 'datastream_update', :dsid => 'contentMetadata', :id => @pid, :content => xml
        expect(response).to have_http_status(:forbidden)
      end
      it 'should error on empty xml' do
        expect { post 'datastream_update', :dsid => 'contentMetadata', :id => @pid, :content => ' ' }.to raise_error(ArgumentError)
      end
      it 'should error on malformed xml' do
        expect { post 'datastream_update', :dsid => 'contentMetadata', :id => @pid, :content => '<this>isnt well formed.' }.to raise_error(ArgumentError)
      end
      it 'should error on missing dsid parameter' do
        expect { post 'datastream_update', :id => @pid, :content => xml }.to raise_error(ArgumentError)
      end

      it 'should display an error message if an invalid APO is entered as governor' do
        @mock_ds = double(Dor::ContentMetadataDS)
        allow(@mock_ds).to receive(:content=).and_return(true)
        allow(@item).to receive(:to_solr).and_raise(ActiveFedora::ObjectNotFoundError)
        allow(@item).to receive(:datastreams).and_return({'contentMetadata' => @mock_ds})
        post 'datastream_update', :dsid => 'contentMetadata', :id => @pid, :content => invalid_apo_xml
        expect(response.code).to eq('404')
        expect(response.body).to include('The object was not found in Fedora. Please recheck the RELS-EXT XML.')
      end
    end
  end
  describe 'update_sequence' do
    before :each do
      @mock_ds = double(Dor::ContentMetadataDS)
      allow(@mock_ds).to receive(:dirty?).and_return(false)
      allow(@mock_ds).to receive(:save)
      allow(@item).to receive(:datastreams).and_return({'contentMetadata' => @mock_ds})
    end
    it 'should 403 if you are not an admin' do
      allow(@current_user).to receive(:is_admin?).and_return(false)
      post 'update_resource', :resource => '0001', :position => '3', :id => @pid
      expect(response.code).to eq('403')
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
  describe 'add_collection' do
    it 'should add a collection' do
      expect(@item).to receive(:add_collection).with('druid:1234')
      post 'add_collection', :id => @pid, :collection => 'druid:1234'
    end
    it 'should 403 if they are not permitted' do
      allow(@current_user).to receive(:is_admin?).and_return(false)
      post 'add_collection', :id => @pid, :collection => 'druid:1234'
      expect(response.code).to eq('403')
    end
  end
  describe 'set_collection' do
    before :each do
      @collection_druid = 'druid:1234'
    end
    it 'should add a collection if there is none yet' do
      allow(@item).to receive(:collections).and_return([])
      expect(@item).to receive(:add_collection).with(@collection_druid)
      post 'set_collection', :id => @pid, :collection => @collection_druid, :bulk => true
      expect(response.code).to eq('200')
    end
    it 'should not add a collection if there is already one' do
      allow(@item).to receive(:collections).and_return(['collection'])
      expect(@item).not_to receive(:add_collection)
      post 'set_collection', :id => @pid, :collection => @collection_druid, :bulk => true
      expect(response.code).to eq('500')
    end
  end
  describe 'remove_collection' do
    it 'should remove a collection' do
      expect(@item).to receive(:remove_collection).with('druid:1234')
      post 'remove_collection', :id => @pid, :collection => 'druid:1234'
    end
    it 'should 403 if they are not permitted' do
      allow(@current_user).to receive(:is_admin?).and_return(false)
      expect(@item).not_to receive(:remove_collection)
      post 'remove_collection', :id => @pid, :collection => 'druid:1234'
      expect(response.code).to eq('403')
    end
  end
  describe 'mods' do
    it 'should return the mods xml for a GET' do
      @request.env['HTTP_ACCEPT'] = 'application/xml'
      xml = '<somexml>stuff</somexml>'
      descmd = double()
      expect(descmd).to receive(:content).and_return(xml)
      expect(@item).to receive(:descMetadata).and_return(descmd)
      get 'mods', :id => @pid
      expect(response.body).to eq(xml)
    end
    it 'should 403 if they are not permitted' do
      allow(@current_user).to receive(:is_admin?).and_return(false)
      get 'mods', :id => @pid
      expect(response.code).to eq('403')
    end
  end
  describe 'add_workflow' do
    before :each do
      @wf = double()
      expect(@item).to receive(:workflows).and_return @wf
    end
    it 'should initialize the new workflow' do
      expect(@item).to receive(:create_workflow)
      expect(@wf).to receive(:[]).with('accessionWF').and_return(nil)
      expect(controller).to receive(:flush_index)
      post 'add_workflow', :id => @pid, :wf => 'accessionWF'
    end
    it 'shouldnt initialize the workflow if one is already active' do
      expect(@item).not_to receive(:create_workflow)
      mock_wf = double()
      expect(mock_wf).to receive(:active?).and_return(true)
      expect(@wf).to receive(:[]).and_return(mock_wf)
      post 'add_workflow', :id => @pid, :wf => 'accessionWF'
    end
  end
  describe '#workflow_view' do
    it 'should require workflow and repo parameters' do
      expect { get :workflow_view, id: @pid, wf_name: 'accessionWF' }.to raise_error(ArgumentError)
    end
    it 'should fetch the workflow on valid parameters' do
      expect(@item.workflows).to receive(:get_workflow)
      get :workflow_view, id: @pid, wf_name: 'accessionWF', repo: 'dor', format: :html
      expect(response).to have_http_status(:ok)
    end
    it 'should 404 on missing item' do
      expect(Dor::Item).to receive(:find).with(@pid).and_raise(ActiveFedora::ObjectNotFoundError)
      get :workflow_view, id: @pid, wf_name: 'accessionWF', repo: 'dor', format: :html
      expect(response).to have_http_status(:not_found)
    end
  end
  describe '#workflow_update' do
    it 'should require various workflow parameters' do
      expect { post :workflow_update, id: @pid, wf_name: 'accessionWF' }.to raise_error(ArgumentError)
    end
    it 'should change the status' do
      expect(Dor::WorkflowObject).to receive(:find_by_name).with('accessionWF').and_return(double(definition: double(repo: 'dor')))
      expect(Dor::Config.workflow.client).to receive(:get_workflow_status).with('dor', @pid, 'accessionWF', 'publish').and_return(nil)
      expect(Dor::Config.workflow.client).to receive(:update_workflow_status).with('dor', @pid, 'accessionWF', 'publish', 'ready').and_return(nil)
      post :workflow_update, id: @pid, wf_name: 'accessionWF', process: 'publish', status: 'ready'
      expect(subject).to redirect_to(catalog_path)
    end
  end
  describe '#file' do
    it 'should require a file parameter' do
      expect { get :file, id: @pid }.to raise_error(ArgumentError)
    end
    it 'should check for a file in the workspace' do
      expect(@item).to receive(:list_files).and_return(['foo.jp2', 'bar.jp2'])
      get :file, id: @pid, file: 'foo.jp2'
      expect(response).to have_http_status(:ok)
      expect(assigns(:available_in_workspace)).to be_truthy
      expect(assigns(:available_in_workspace_error)).to be_nil
    end
    it 'should handle missing files in the workspace' do
      expect(@item).to receive(:list_files).and_return(['foo.jp2', 'bar.jp2'])
      get :file, id: @pid, file: 'bar.tif'
      expect(response).to have_http_status(:ok)
      expect(assigns(:available_in_workspace)).to be_falsey
      expect(assigns(:available_in_workspace_error)).to be_nil
    end
    it 'should handle SFTP errors' do
      expect(@item).to receive(:list_files).and_raise(Net::SSH::AuthenticationFailed)
      get :file, id: @pid, file: 'foo.jp2'
      expect(response).to have_http_status(:ok)
      expect(assigns(:available_in_workspace)).to be_falsey
      expect(assigns(:available_in_workspace_error)).to match(/Net::SSH::AuthenticationFailed/)
    end
  end
end
