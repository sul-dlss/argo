require 'spec_helper'

RSpec.describe ItemsController, :type => :controller do
  before do
    @pid  = 'druid:oo201oo0001'
    @item = Dor::Item.new pid: @pid
    allow_any_instance_of(User).to receive(:roles).and_return([])
    allow(controller).to receive(:current_user).and_return(user)
    allow(Dor).to receive(:find).with(@pid).and_return(@item)
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
    allow(@item).to receive(:datastreams).and_return('identityMetadata' => idmd, 'events' => Dor::EventsDS.new)
    allow(@item).to receive(:allows_modification?).and_return(true)
    allow(@item).to receive(:can_manage_item?).and_return(false)
    allow(@item).to receive(:can_manage_content?).and_return(false)
    allow(@item).to receive(:can_view_content?).and_return(false)
    allow(@item).to receive(:pid).and_return('object:pid')
    allow(@item).to receive(:admin_policy_object).and_return(apo)
    allow(@item).to receive(:workflows).and_return(wf)
    allow(Dor::SearchService.solr).to receive(:add)
  end

  let(:user) { create(:user) }

  describe 'release_hold' do
    it 'should release an item that is on hold if its apo has been ingested' do
      expect(Dor::Config.workflow.client).to receive(:get_workflow_status).with('dor', 'object:pid', 'accessionWF', 'sdr-ingest-transfer').and_return('hold')
      expect(Dor::Config.workflow.client).to receive(:get_lifecycle).with('dor', 'druid:apo', 'accessioned').and_return(true)
      expect(Dor::Config.workflow.client).to receive(:update_workflow_status)
      post :release_hold, params: { :id => @pid }
    end
    it 'should refuse to release an item that isnt on hold' do
      expect(Dor::Config.workflow.client).to receive(:get_workflow_status).with('dor', 'object:pid', 'accessionWF', 'sdr-ingest-transfer').and_return('waiting')
      expect(Dor::Config.workflow.client).not_to receive(:update_workflow_status)
      post :release_hold, params: { :id => @pid }
    end
    it 'should refuse to release an item whose apo hasnt been ingested' do
      expect(Dor::Config.workflow.client).to receive(:get_workflow_status).with('dor', 'object:pid', 'accessionWF', 'sdr-ingest-transfer').and_return('hold')
      expect(Dor::Config.workflow.client).to receive(:get_lifecycle).with('dor', 'druid:apo', 'accessioned').and_return(false)
      expect(Dor::Config.workflow.client).not_to receive(:update_workflow_status)
      post :release_hold, params: { :id => @pid }
    end
  end

  describe '#purge_object' do
    context "when they don't have manage_content access" do
      it 'returns 403' do
        allow(controller).to receive(:authorize!).with(:manage_content, Dor::Item).and_raise(CanCan::AccessDenied)
        post 'purge_object', params: { :id => @pid }
        expect(response.code).to eq('403')
      end
    end

    context 'when they have manage_content access' do
      before do
        allow(controller).to receive(:authorize!).and_return(true)
      end

      it 'redirects to root and flashes a confirmation notice when successful' do
        post 'purge_object', params: { :id => @pid }
        expect(response.code).to eq('302')
        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to eq("#{@pid} has been purged!")
      end

      it 'deletes the object from fedora and solr' do
        expect(@item).to receive(:delete)
        expect(Dor::SearchService.solr).to receive(:delete_by_id).with(@pid)
        expect(Dor::SearchService.solr).to receive(:commit)
        post 'purge_object', params: { :id => @pid }
      end

      it 'blocks purge on submitted objects' do
        expect(controller).to receive(:dor_lifecycle).with(@item, 'submitted').and_return(true)
        post 'purge_object', params: { :id => @pid }
        expect(response.code).to eq('403')
        expect(response.body).to eq('Cannot purge an object after it is submitted.')
      end
    end
  end

  describe '#embargo_update' do
    context "when they don't have manage_item access" do
      it 'returns 403' do
        allow(controller).to receive(:authorize!).with(:manage_item, Dor::Item).and_raise(CanCan::AccessDenied)
        expect(subject).not_to receive(:save_and_reindex)
        expect(subject).not_to receive(:flush_index)
        post :embargo_update, params: { id: @pid, embargo_date: '2100-01-01' }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when they have manage_content access' do
      before do
        allow(controller).to receive(:authorize!).and_return(true)
      end

      it 'calls Dor::Item.update_embargo' do
        expect(@item).to receive(:update_embargo)
        expect(@item.datastreams['events']).to receive(:add_event).and_call_original
        expect(controller).to receive(:save_and_reindex)
        expect(controller).to receive(:flush_index).and_call_original
        expect(Dor::SearchService.solr).to receive(:commit) # from flush_index internals
        post :embargo_update, params: { :id => @pid, :embargo_date => '2100-01-01' }
        expect(response).to have_http_status(:found) # redirect to catalog page
      end
      it 'requires a date' do
        expect { post :embargo_update, params: { :id => @pid } }.to raise_error(ArgumentError)
      end
      it 'dies on a malformed date' do
        expect { post :embargo_update, params: { :id => @pid, :embargo_date => 'not-a-date' } }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#register' do
    it 'loads the registration form' do
      get :register
      expect(response).to render_template('register')
    end
  end

  describe '#open_version' do
    context 'when they have manage_content access' do
      before do
        allow(controller).to receive(:authorize!).and_return(true)
      end

      it 'calls dor-services to open a new version' do
        allow(@item).to receive(:open_new_version)
        vers_md_upd_info = { significance: 'major', description: 'something', opening_user_name: user.to_s }
        expect(@item).to receive(:open_new_version).with(vers_md_upd_info: vers_md_upd_info)
        expect(@item).to receive(:save)
        expect(Dor::SearchService.solr).to receive(:add)
        get 'open_version', params: { id: @pid, severity: vers_md_upd_info[:significance], description: vers_md_upd_info[:description] }
      end
    end

    context 'without manage content access' do
      it 'returns a 403' do
        allow(controller).to receive(:authorize!).with(:manage_content, Dor::Item).and_raise(CanCan::AccessDenied)
        get 'open_version', params: { :id => @pid, :severity => 'major', :description => 'something' }
        expect(response.code).to eq('403')
      end
    end
  end

  describe '#close_version' do
    context 'when they have manage_content access' do
      before do
        allow(controller).to receive(:authorize!).and_return(true)
      end

      it 'calls dor-services to close the version' do
        expect(@item).to receive(:close_version)
        version_metadata = double(Dor::VersionMetadataDS)
        allow(version_metadata).to receive(:current_version_id).and_return(2)
        allow(@item).to receive(:versionMetadata).and_return(version_metadata)
        expect(version_metadata).to receive(:update_current_version)
        allow(@item).to receive(:current_version).and_return('2')
        expect(@item).to receive(:save)
        expect(Dor::SearchService.solr).to receive(:add)
        get 'close_version', params: { :id => @pid, :severity => 'major', :description => 'something' }
      end
    end

    context 'without manage content access' do
      it 'returns a 403' do
        allow(controller).to receive(:authorize!).with(:manage_content, Dor::Item).and_raise(CanCan::AccessDenied)
        get 'close_version', params: { :id => @pid }
        expect(response.code).to eq('403')
      end
    end
  end

  describe '#source_id' do
    context 'when they have manage_content access' do
      before do
        allow(controller).to receive(:authorize!).and_return(true)
      end

      it 'updates the source id' do
        expect(@item).to receive(:source_id=).with('new:source_id')
        expect(Dor::SearchService.solr).to receive(:add)
        post 'source_id', params: { :id => @pid, :new_id => 'new:source_id' }
      end
    end
  end

  describe '#catkey' do
    context 'without manage content access' do
      it 'returns a 403' do
        allow(controller).to receive(:authorize!).with(:manage_content, Dor::Item).and_raise(CanCan::AccessDenied)
        post 'catkey', params: { :id => @pid, :new_catkey => '12345' }
        expect(response.code).to eq('403')
      end
    end

    context 'when they have manage_content access' do
      before do
        allow(controller).to receive(:authorize!).and_return(true)
      end

      it 'updates the catkey, trimming whitespace' do
        expect(@item).to receive(:catkey=).with('12345')
        expect(Dor::SearchService.solr).to receive(:add)
        post 'catkey', params: { :id => @pid, :new_catkey => '   12345 ' }
      end
    end
  end

  describe '#tags' do
    context 'when they have manage_content access' do
      before do
        allow(controller).to receive(:authorize!).and_return(true)
        allow(@item).to receive(:tags).and_return(['some:thing'])
        expect(Dor::SearchService.solr).to receive(:add)
      end

      it 'updates tags' do
        expect(@item).to receive(:update_tag).with('some:thing', 'some:thingelse')
        post 'tags', params: { :id => @pid, :update => 'true', :tag1 => 'some:thingelse' }
      end
      it 'deletes tag' do
        expect(@item).to receive(:remove_tag).with('some:thing').and_return(true)
        post 'tags', params: { :id => @pid, :tag => '1', :del => 'true' }
      end
      it 'adds a tag' do
        expect(@item).to receive(:add_tag).with('new:thing')
        post 'tags', params: { :id => @pid, :new_tag1 => 'new:thing', :add => 'true' }
      end
    end
  end

  describe '#tags_bulk' do
    context 'when they have manage_content access' do
      before do
        allow(controller).to receive(:authorize!).and_return(true)
        allow(@item).to receive(:tags).and_return(['some:thing'])
        expect(@item.datastreams['identityMetadata']).to receive(:save)
        expect(Dor::SearchService.solr).to receive(:add)
      end

      it 'removes an old tag an add a new one' do
        expect(@item).to receive(:remove_tag).with('some:thing').and_return(true)
        expect(@item).to receive(:add_tag).with('new:thing').and_return(true)
        post 'tags_bulk', params: { :id => @pid, :tags => 'new:thing' }
      end
      it 'adds multiple tags' do
        expect(@item).to receive(:add_tag).twice
        expect(@item).to receive(:remove_tag).with('some:thing').and_return(true)
        expect(@item).to receive(:save)
        post 'tags_bulk', params: { :id => @pid, :tags => 'Process : Content Type : Book (ltr)	 Registered By : labware' }
      end
    end
  end

  describe '#set_rights' do
    it 'sets an item to dark' do
      expect(@item).to receive(:set_read_rights).with('dark')
      get 'set_rights', params: { :id => @pid, :rights => 'dark' }
    end
  end

  describe '#update_attributes' do
    before do
      @content_md = double(Dor::ContentMetadataDS)
      allow(@item).to receive(:contentMetadata).and_return(@content_md)
    end
    context 'when they have manage_content access' do
      before do
        allow(controller).to receive(:authorize!).and_return(true)
      end
      it 'updates the shelve, publish and preserve to yes (used to be true)' do
        allow(@content_md).to receive(:update_attributes) do |file, publish, shelve, preserve|
          expect(shelve).to eq('yes')
          expect(preserve).to eq('yes')
          expect(publish).to eq('yes')
        end
        post 'update_attributes', params: { :shelve => 'on', :publish => 'on', :preserve => 'on', :id => @pid, :file_name => 'something.txt' }
      end

      it 'works if not all of the values are set' do
        allow(@content_md).to receive(:update_attributes) do |file, publish, shelve, preserve|
          expect(shelve).to eq('no')
          expect(preserve).to eq('yes')
          expect(publish).to eq('yes')
        end
        post 'update_attributes', params: { :publish => 'on', :preserve => 'on', :id => @pid, :file_name => 'something.txt' }
      end

      it 'updates the shelve, publish and preserve to no (used to be false)' do
        allow(@content_md).to receive(:update_attributes) do |file, publish, shelve, preserve|
          expect(shelve).to eq('no')
          expect(preserve).to eq('no')
          expect(publish).to eq('no')
        end
        expect(@content_md).to receive(:update_attributes)
        post 'update_attributes', params: { :shelve => 'no', :publish => 'no', :preserve => 'no', :id => @pid, :file_name => 'something.txt' }
      end
    end

    context 'without manage content access' do
      it 'returns a 403' do
        allow(controller).to receive(:authorize!).with(:manage_content, Dor::Item).and_raise(CanCan::AccessDenied)
        post 'update_attributes', params: { :shelve => 'no', :publish => 'no', :preserve => 'no', :id => @pid, :file_name => 'something.txt' }
        expect(response.code).to eq('403')
      end
    end
  end

  describe '#get_file' do
    context 'when they have manage_content access' do
      before do
        allow(controller).to receive(:authorize!).and_return(true)
      end
      it 'should have dor-services fetch a file from the workspace' do
        allow(@item).to receive(:get_file).and_return('abc')
        expect(@item).to receive(:get_file)
        allow(Time).to receive(:now).and_return(Time.parse 'Mon, 30 Nov 2015 20:19:43 UTC')
        get 'get_file', params: { :file => 'somefile.txt', :id => @pid }
        expect(response.headers['Last-Modified']).to eq 'Mon, 30 Nov 2015 20:19:43 -0000'
      end
    end

    context 'when the user can not view_content' do
      before do
        allow(controller).to receive(:authorize!).with(:view_content, Dor::Item).and_raise(CanCan::AccessDenied)
      end

      it 'returns a 403' do
        get 'get_file', params: { :file => 'somefile.txt', :id => @pid }
        expect(response.code).to eq('403')
      end
    end
  end

  describe '#get_preserved_file' do
    context 'when they have manage_content access' do
      before do
        allow(controller).to receive(:authorize!).and_return(true)
      end

      it 'returns a response with the preserved file content as the body and the right headers' do
        mock_file_name = 'preserved_file'
        mock_version = 2
        mock_content = 'preserved file content'
        allow(@item).to receive(:get_preserved_file).with(mock_file_name, mock_version).and_return(mock_content)

        last_modified_lower_bound = Time.now.utc.rfc2822
        get 'get_preserved_file', params: { :file => mock_file_name, :version => mock_version, :id => @pid }
        expect(response.headers['Last-Modified']).to be <= Time.now.utc.rfc2822
        expect(response.headers['Last-Modified']).to be >= last_modified_lower_bound
        expect(response.headers['Content-Type']).to eq('application/octet-stream')
        expect(response.headers['Content-Disposition']).to eq("attachment; filename=#{mock_file_name}")
        expect(response.code).to eq('200')
        expect(response.body).to eq(mock_content)
      end
    end
  end

  describe '#datastream_update' do
    let(:xml) { '<contentMetadata/>' }
    let(:invalid_apo_xml) { '<hydra:isGovernedBy rdf:resource="info:fedora/druid:not_exist"/>' }

    context 'without management access' do
      before do
        allow(controller).to receive(:authorize!).with(:manage_content, Dor::Item).and_raise(CanCan::AccessDenied)
      end
      it 'prevents access' do
        expect(@item).not_to receive(:save)
        post 'datastream_update', params: { :dsid => 'contentMetadata', :id => @pid, :content => xml }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when they have manage_content access' do
      before do
        allow(controller).to receive(:authorize!).and_return(true)
      end

      it 'updates the datastream' do
        expect(@item).to receive(:datastreams).and_return(
          'contentMetadata' => double(Dor::ContentMetadataDS, :'content=' => xml)
        )
        expect(@item).to receive(:save)
        expect(controller).to receive(:authorize!).with(:manage_content, Dor::Item).and_return(true)
        post 'datastream_update', params: { :dsid => 'contentMetadata', :id => @pid, :content => xml }
        expect(response).to have_http_status(:found)
      end

      it 'errors on empty xml' do
        expect { post 'datastream_update', params: { :dsid => 'contentMetadata', :id => @pid, :content => ' ' } }.to raise_error(ArgumentError)
      end
      it 'errors on malformed xml' do
        expect { post 'datastream_update', params: { :dsid => 'contentMetadata', :id => @pid, :content => '<this>isnt well formed.' } }.to raise_error(ArgumentError)
      end
      it 'errors on missing dsid parameter' do
        expect { post 'datastream_update', params: { :id => @pid, :content => xml } }.to raise_error(ArgumentError)
      end

      it 'displays an error message if an invalid APO is entered as governor' do
        @mock_ds = double(Dor::ContentMetadataDS)
        allow(@mock_ds).to receive(:content=).and_return(true)
        allow(@item).to receive(:to_solr).and_raise(ActiveFedora::ObjectNotFoundError)
        allow(@item).to receive(:datastreams).and_return('contentMetadata' => @mock_ds)
        post 'datastream_update', params: { :dsid => 'contentMetadata', :id => @pid, :content => invalid_apo_xml }
        expect(response.code).to eq('404')
        expect(response.body).to include('The object was not found in Fedora. Please recheck the RELS-EXT XML.')
      end
    end
  end

  describe '#update_resource' do
    before do
      @mock_ds = double(Dor::ContentMetadataDS)
      allow(@mock_ds).to receive(:dirty?).and_return(false)
      allow(@mock_ds).to receive(:save)
      allow(@item).to receive(:datastreams).and_return('contentMetadata' => @mock_ds)
    end

    context 'without manage content access' do
      it 'returns a 403' do
        allow(controller).to receive(:authorize!).with(:manage_content, Dor::Item).and_raise(CanCan::AccessDenied)
        post 'update_resource', params: { :resource => '0001', :position => '3', :id => @pid }
        expect(response.code).to eq('403')
      end
    end
    context 'when they have manage_content access' do
      before do
        allow(controller).to receive(:authorize!).and_return(true)
      end
      it 'calls dor-services to reorder the resources' do
        expect(@item).to receive(:move_resource)
        post 'update_resource', params: { :resource => '0001', :position => '3', :id => @pid }
      end
      it 'calls dor-services to change the label' do
        expect(@item).to receive(:update_resource_label)
        post 'update_resource', params: { :resource => '0001', :label => 'label!', :id => @pid }
      end
      it 'calls dor-services to update the resource type' do
        expect(@item).to receive(:update_resource_type)
        post 'update_resource', params: { :resource => '0001', :type => 'book', :id => @pid }
      end
    end
  end

  describe '#add_collection' do
    context 'when they have manage_content access' do
      before do
        allow(controller).to receive(:authorize!).and_return(true)
      end
      it 'adds a collection' do
        expect(@item).to receive(:add_collection).with('druid:1234')
        post 'add_collection', params: { :id => @pid, :collection => 'druid:1234' }
      end
    end

    context "when they don't have manage_content access" do
      it 'returns 403' do
        allow(controller).to receive(:authorize!).with(:manage_content, Dor::Item).and_raise(CanCan::AccessDenied)
        post 'add_collection', params: { :id => @pid, :collection => 'druid:1234' }
        expect(response.code).to eq('403')
      end
    end
  end

  describe '#set_collection' do
    before do
      @collection_druid = 'druid:1234'
    end
    context 'when they have manage_content access' do
      before do
        allow(controller).to receive(:authorize!).and_return(true)
      end
      it 'adds a collection if there is none yet' do
        allow(@item).to receive(:collections).and_return([])
        expect(@item).to receive(:add_collection).with(@collection_druid)
        post 'set_collection', params: { :id => @pid, :collection => @collection_druid, :bulk => true }
        expect(response.code).to eq('200')
      end

      it 'does not add a collection if there is already one' do
        allow(@item).to receive(:collections).and_return(['collection'])
        expect(@item).not_to receive(:add_collection)
        post 'set_collection', params: { :id => @pid, :collection => @collection_druid, :bulk => true }
        expect(response.code).to eq('500')
      end
    end
  end

  describe '#remove_collection' do
    context 'when they have manage_content access' do
      before do
        allow(controller).to receive(:authorize!).and_return(true)
      end
      it 'removes a collection' do
        expect(@item).to receive(:remove_collection).with('druid:1234')
        post 'remove_collection', params: { :id => @pid, :collection => 'druid:1234' }
      end
    end

    context "when they don't have manage_content access" do
      it 'returns 403' do
        allow(controller).to receive(:authorize!).with(:manage_content, Dor::Item).and_raise(CanCan::AccessDenied)
        expect(@item).not_to receive(:remove_collection)
        post 'remove_collection', params: { :id => @pid, :collection => 'druid:1234' }
        expect(response.code).to eq('403')
      end
    end
  end

  describe '#mods' do
    context 'when they have manage_content access' do
      before do
        allow(controller).to receive(:authorize!).and_return(true)
      end
      it 'returns the mods xml for a GET' do
        @request.env['HTTP_ACCEPT'] = 'application/xml'
        xml = '<somexml>stuff</somexml>'
        descmd = double()
        expect(descmd).to receive(:content).and_return(xml)
        expect(@item).to receive(:descMetadata).and_return(descmd)
        get 'mods', params: { :id => @pid }
        expect(response.body).to eq(xml)
      end
    end

    context "when they don't have manage_content access" do
      it 'returns 403' do
        allow(controller).to receive(:authorize!).with(:manage_content, Dor::Item).and_raise(CanCan::AccessDenied)
        get 'mods', params: { :id => @pid }
        expect(response.code).to eq('403')
      end
    end
  end

  describe '#add_workflow' do
    context 'when they have manage_content access' do
      before do
        allow(controller).to receive(:authorize!).and_return(true)
        @wf = double()
        expect(@item).to receive(:workflows).and_return @wf
      end
      it 'initializes the new workflow' do
        expect(@item).to receive(:create_workflow)
        expect(@wf).to receive(:[]).with('accessionWF').and_return(nil)
        expect(controller).to receive(:flush_index)
        post 'add_workflow', params: { :id => @pid, :wf => 'accessionWF' }
      end

      it "shouldn't initialize the workflow if one is already active" do
        expect(@item).not_to receive(:create_workflow)
        mock_wf = double()
        expect(mock_wf).to receive(:active?).and_return(true)
        expect(@wf).to receive(:[]).and_return(mock_wf)
        post 'add_workflow', params: { :id => @pid, :wf => 'accessionWF' }
      end
    end
  end

  describe '#workflow_view' do
    it 'requires workflow and repo parameters' do
      expect { get :workflow_view, params: { id: @pid, wf_name: 'accessionWF' } }.to raise_error(ArgumentError)
    end
    it 'fetches the workflow on valid parameters' do
      expect(@item.workflows).to receive(:get_workflow)
      get :workflow_view, params: { id: @pid, wf_name: 'accessionWF', repo: 'dor', format: :html }
      expect(response).to have_http_status(:ok)
    end
    it 'returns 404 on missing item' do
      expect(Dor).to receive(:find).with(@pid).and_raise(ActiveFedora::ObjectNotFoundError)
      get :workflow_view, params: { id: @pid, wf_name: 'accessionWF', repo: 'dor', format: :html }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe '#workflow_update' do
    it 'requires various workflow parameters' do
      expect { post :workflow_update, params: { id: @pid, wf_name: 'accessionWF' } }.to raise_error(ArgumentError)
    end
    it 'changes the status' do
      expect(Dor::WorkflowObject).to receive(:find_by_name).with('accessionWF').and_return(double(definition: double(repo: 'dor')))
      expect(Dor::Config.workflow.client).to receive(:get_workflow_status).with('dor', @pid, 'accessionWF', 'publish').and_return(nil)
      expect(Dor::Config.workflow.client).to receive(:update_workflow_status).with('dor', @pid, 'accessionWF', 'publish', 'ready').and_return(nil)
      post :workflow_update, params: { id: @pid, wf_name: 'accessionWF', process: 'publish', status: 'ready' }
      expect(subject).to redirect_to(solr_document_path(@pid))
    end
  end

  describe '#file' do
    it 'requires a file parameter' do
      expect { get :file, params: { id: @pid } }.to raise_error(ArgumentError)
    end
    it 'checks for a file in the workspace' do
      expect(@item).to receive(:list_files).and_return(['foo.jp2', 'bar.jp2'])
      get :file, params: { id: @pid, file: 'foo.jp2' }
      expect(response).to have_http_status(:ok)
      expect(assigns(:available_in_workspace)).to be_truthy
      expect(assigns(:available_in_workspace_error)).to be_nil
    end
    it 'handles missing files in the workspace' do
      expect(@item).to receive(:list_files).and_return(['foo.jp2', 'bar.jp2'])
      get :file, params: { id: @pid, file: 'bar.tif' }
      expect(response).to have_http_status(:ok)
      expect(assigns(:available_in_workspace)).to be_falsey
      expect(assigns(:available_in_workspace_error)).to be_nil
    end
    it 'handles SFTP errors' do
      expect(@item).to receive(:list_files).and_raise(Net::SSH::AuthenticationFailed)
      get :file, params: { id: @pid, file: 'foo.jp2' }
      expect(response).to have_http_status(:ok)
      expect(assigns(:available_in_workspace)).to be_falsey
      expect(assigns(:available_in_workspace_error)).to match(/Net::SSH::AuthenticationFailed/)
    end
  end

  describe '#refresh_metadata' do
    context 'when they have manage_content access' do
      before do
        allow(controller).to receive(:authorize!).and_return(true)
      end
      it 'returns a 403 with an error message if there is no catkey' do
        expect(@item).to receive(:catkey).and_return('')
        get :refresh_metadata, params: { id: @pid }
        expect(response).to have_http_status(:forbidden)
        expect(response.body).to eq 'object must have catkey to refresh descMetadata'
      end

      context 'there is a catkey present' do
        let(:descmd) { double(Dor::DescMetadataDS, ng_xml: double(Nokogiri::XML::Document, to_s: '<somexml>refreshed metadata</somexml>')) }
        before(:each) do
          allow(@item).to receive(:catkey).and_return('12345')
          allow(@item).to receive(:descMetadata).and_return(descmd)
        end
        context 'user has permission and object is editable' do
          before(:each) do
            expect(@item).to receive(:build_datastream).with('descMetadata', true)
            expect(descmd).to receive(:content=).with(descmd.ng_xml.to_s)
            expect(controller).to receive(:save_and_reindex)
          end
          it 'redirects with a notice if there is a catkey and the operation is not part of a bulk update' do
            get :refresh_metadata, params: { id: @pid }
            expect(response).to redirect_to(solr_document_path(@pid))
            expect(flash[:notice]).to eq "Metadata for #{@item.pid} successfully refreshed from catkey:12345"
          end
          it 'returns a 200 with a plaintext message if the operation is part of a bulk update' do
            get :refresh_metadata, params: { id: @pid, :bulk => true }
            expect(response).to have_http_status(:ok)
            expect(response.body).to eq 'Refreshed.'
          end
        end

        context "object doesn't allow modification or user doesn't have permission to edit desc metadata" do
          before(:each) do
            expect(@item).not_to receive(:build_datastream)
            expect(descmd).not_to receive(:content=)
            expect(controller).not_to receive(:save_and_reindex)
          end
          it 'returns a 403 with an error message if the user is not allowed to edit desc metadata' do
            expect(controller).to receive(:authorize!).with(:manage_desc_metadata, @item).and_raise(CanCan::AccessDenied)
            get :refresh_metadata, params: { id: @pid }
            expect(response).to have_http_status(:forbidden)
            expect(response.body).to eq 'forbidden'
          end
          it "returns a 403 with an error message if the object doesn't allow modification" do
            expect(@item).to receive(:allows_modification?).and_return(false)
            get :refresh_metadata, params: { id: @pid }
            expect(response).to have_http_status(:forbidden)
            expect(response.body).to eq 'Object cannot be modified in its current state.'
          end
        end
      end
    end
  end

  describe '#create_obj_and_apo' do
    it 'loads an APO object so that it has the appropriate model type (according to the solr doc)' do
      expect(Dor).to receive(:find).with('druid:zt570tx3016').and_call_original # override the earlier Dor.find expectation
      allow(Dor).to receive(:find).with('druid:hv992ry2431') # create_obj_and_apo will try to lookup the APO's APO
      subject.send(:create_obj_and_apo, 'druid:zt570tx3016')
      expect(subject.instance_variable_get(:@object).to_solr).to include('active_fedora_model_ssi' => 'Dor::AdminPolicyObject',
                                                                         'has_model_ssim' => 'info:fedora/afmodel:Dor_AdminPolicyObject')
    end
    it 'loads an Item object so that it has the appropriate model type (according to the solr doc)' do
      expect(Dor).to receive(:find).with('druid:hj185vb7593').and_call_original # override the earlier Dor.find expectation
      allow(Dor).to receive(:find).with('druid:ww057vk7675') # create_obj_and_apo will try to lookup the Item's APO
      subject.send(:create_obj_and_apo, 'druid:hj185vb7593')
      expect(subject.instance_variable_get(:@object).to_solr).to include('active_fedora_model_ssi' => 'Dor::Item',
                                                                         'has_model_ssim' => 'info:fedora/afmodel:Dor_Item')
    end
  end

  describe '#set_governing_apo' do
    let(:new_apo_id) { 'druid:ab123cd4567' }
    context 'object modification not allowed, user authorized to manage governing APOs' do
      before do
        allow(@item).to receive(:allows_modification?).and_return(false)
        allow(controller).to receive(:authorize!).with(:manage_governing_apo, @item, new_apo_id)
      end
      it 'should return a 403' do
        expect(@item).not_to receive(:admin_policy_object=)
        expect(@item.identityMetadata).not_to receive(:adminPolicy)
        expect(@item.datastreams['identityMetadata']).not_to receive(:adminPolicy=)
        post :set_governing_apo, params: { id: @pid, new_apo_id: new_apo_id }
        expect(response).to have_http_status(:forbidden)
        expect(response.body).to eq 'Object cannot be modified in its current state.'
      end
    end
    context 'object modification not allowed, user not authorized to manage governing APOs' do
      before do
        allow(@item).to receive(:allows_modification?).and_return(false)
        allow(controller).to receive(:authorize!).with(:manage_governing_apo, @item, new_apo_id).and_raise(CanCan::AccessDenied)
      end
      it 'should return a 403' do
        expect(@item).not_to receive(:admin_policy_object=)
        expect(@item.identityMetadata).not_to receive(:adminPolicy)
        expect(@item.datastreams['identityMetadata']).not_to receive(:adminPolicy=)
        post :set_governing_apo, params: { id: @pid, new_apo_id: new_apo_id }
        expect(response).to have_http_status(:forbidden)
        expect(response.body).to eq 'forbidden'
      end
    end
    context 'object modification allowed, user not authorized to manage governing APOs' do
      before do
        allow(@item).to receive(:allows_modification?).and_return(true)
        allow(controller).to receive(:authorize!).with(:manage_governing_apo, @item, new_apo_id).and_raise(CanCan::AccessDenied)
      end
      it 'should return a 403' do
        expect(@item).not_to receive(:admin_policy_object=)
        expect(@item.identityMetadata).not_to receive(:adminPolicy)
        expect(@item.datastreams['identityMetadata']).not_to receive(:adminPolicy=)
        post :set_governing_apo, params: { id: @pid, new_apo_id: new_apo_id }
        expect(response).to have_http_status(:forbidden)
        expect(response.body).to eq 'forbidden'
      end
    end
    context 'object modification allowed, user authorized to manage governing APOs' do
      let(:new_apo) { double(Dor::AdminPolicyObject, id: new_apo_id) }
      before do
        allow(@item).to receive(:allows_modification?).and_return(true)
        allow(controller).to receive(:authorize!).with(:manage_governing_apo, @item, new_apo_id)
        allow(Dor).to receive(:find).with(new_apo_id).and_return(new_apo)
      end
      it 'should successfully update the governing APO' do
        expect(@item).to receive(:admin_policy_object=).with(new_apo)
        expect(@item.identityMetadata).to receive(:adminPolicy).and_return(double(Dor::AdminPolicyObject))
        expect(@item.datastreams['identityMetadata']).to receive(:adminPolicy=).with(nil)
        post :set_governing_apo, params: { id: @pid, new_apo_id: new_apo_id }
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(solr_document_path(@pid))
        expect(flash[:notice]).to eq 'Governing APO updated!'
      end
      it 'should reject requests in the old (deprecated) bulk update mode' do
        expect(@item).not_to receive(:admin_policy_object=)
        expect(@item.identityMetadata).not_to receive(:adminPolicy)
        expect(@item.datastreams['identityMetadata']).not_to receive(:adminPolicy=)
        post :set_governing_apo, params: { id: @pid, new_apo_id: new_apo_id, bulk: true }
        expect(response).to have_http_status(:forbidden)
        expect(response.body).to eq 'the old bulk update mechanism is deprecated.  please use the new bulk actions framework going forward.'
      end
    end
  end
end
