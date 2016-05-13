# encoding: UTF-8

require 'spec_helper'
describe ApoController, :type => :controller do

  before :each do
    @apo = instantiate_fixture('zt570tx3016', Dor::AdminPolicyObject)
    allow(Dor).to receive(:find).with(@apo.pid).and_return(@apo)
    allow(@apo).to receive(:save)

    @collection = instantiate_fixture('pb873ty1662', Dor::Collection)
    allow(Dor).to receive(:find).with(@collection.pid).and_return(@collection)
    allow(@collection).to receive(:save)

    @agreement = instantiate_fixture('dd327qr3670', Dor::Item)
    allow(Dor).to receive(:find).with(@agreement.pid).and_return(@agreement)

    allow(controller).to receive(:update_index)

    log_in_as_mock_user(subject, is_admin?: true)
  end

  describe 'create' do
    before :each do
      @example = { # These data mimic the APO registration form
        'title' => 'New APO Title',
        'agreement' => @agreement.pid,
        'desc_md' => 'MODS',
        'metadata_source' => 'DOR',
        'managers' => 'dlss:developers dlss:dpg-staff',
        'viewers' => 'sdr:viewer-role , dlss:forensics-staff',
        'collection_radio' => 'create',
        'collection_title' => 'col title',
        'collection_abstract' => '',
        'default_object_rights' => 'world',
        'use' => '',
        'copyright' => '',
        'use_license' => 'by-nc',
        'workflow' => 'accessionWF',
        'register' => ''
      }
    end

    it 'should hit the registration service to register both an APO and a collection' do
      # verify that an APO is registered
      expect(@apo).to receive(:add_roleplayer).exactly(4).times
      expect(Dor::RegistrationService).to receive(:create_from_request) do |params|
        expect(params).to match a_hash_including(
          :label        => 'New APO Title',
          :object_type  => 'adminPolicy',
          :admin_policy => 'druid:hv992ry2431', # Uber-APO
          :workflow_priority => '70'
        )
        expect(params[:metadata_source]).to be_nil # descMD is created via the form
        { :pid => @apo.pid }
      end
      expect(@apo).to receive(:"use_license=").with(@example['use_license'])

      # verify that the collection is also created
      expect(@apo).to receive(:add_default_collection).with(@collection.pid)
      expect(Dor::RegistrationService).to receive(:create_from_request) do |params|
        expect(params).to match a_hash_including(
          :label        => 'col title',
          :object_type  => 'collection',
          :admin_policy => @apo.pid,
          :workflow_priority => '65'
        )
        { :pid => @collection.pid }
      end

      post 'register', @example
    end

    context 'APO Metadata' do
      before(:each) do
        @md_info = {
          copyright:    'My copyright statement',
          use:          'My use and reproduction statement',
          title:        'My title',
          desc_md:      'MODS',
          metadata_source: 'DOR',
          agreement:    @agreement.pid,
          workflow:     'registrationWF',
          default_object_rights: 'world',
          use_license:  'by-nc'
        }
      end
      it 'should set clean APO metadata for defaultObjectRights' do
        expect(subject.respond_to?(:set_apo_metadata)).to be_truthy
        subject.set_apo_metadata(@apo, @md_info)

        # rubocop:disable Style/SingleSpaceBeforeFirstArg
        expect(@apo.mods_title).to           eq(@md_info[:title])
        expect(@apo.desc_metadata_format).to eq(@md_info[:desc_md])
        expect(@apo.metadata_source).to      eq(@md_info[:metadata_source])
        expect(@apo.agreement).to            eq(@md_info[:agreement])
        expect(@apo.default_workflows).to    eq([@md_info[:workflow]])
        expect(@apo.default_rights).to       eq(@md_info[:default_object_rights].capitalize)
        expect(@apo.use_license).to          eq(@md_info[:use_license])
        expect(@apo.use_license_uri).to      eq(Dor::Editable::CREATIVE_COMMONS_USE_LICENSES[@md_info[:use_license]][:uri])
        expect(@apo.use_license_human).to    eq(Dor::Editable::CREATIVE_COMMONS_USE_LICENSES[@md_info[:use_license]][:human_readable])
        expect(@apo.copyright_statement).to  eq(@md_info[:copyright])
        expect(@apo.use_statement).to        eq(@md_info[:use])
        doc = Nokogiri::XML(File.read('spec/fixtures/apo_defaultObjectRights_clean.xml'))
        expect(@apo.defaultObjectRights.content).to be_equivalent_to(doc)
      end
      it 'should handle no use license' do
        @md_info[:use_license] = ' '
        subject.set_apo_metadata(@apo, @md_info)
        expect(@apo.use_license).to          eq('')
        expect(@apo.use_license_uri).to      be_nil
        expect(@apo.use_license_human).to    eq('')
      end
      it 'should handle no copyright statement' do
        @md_info[:copyright] = ' '
        subject.set_apo_metadata(@apo, @md_info)
        expect(@apo.copyright_statement).to be_nil
      end
      it 'should handle UTF8 copyright statement' do
        @md_info[:copyright] = 'Copyright © All Rights Reserved.'
        subject.set_apo_metadata(@apo, @md_info)
        expect(@apo.copyright_statement).to eq(@md_info[:copyright])
      end
      it 'should handle no use statement' do
        @md_info[:use] = ' '
        subject.set_apo_metadata(@apo, @md_info)
        expect(@apo.use_statement).to be_nil
      end
      it 'should error out if no workflow' do
        @md_info[:workflow] = ' '
        expect { subject.set_apo_metadata(@apo, @md_info) }.to raise_error(ArgumentError)
      end
    end
  end

  describe 'register_collection' do
    it 'should show the create collection form' do
      get :register_collection, 'id' => @apo.pid
      expect(response).to have_http_status(:ok)
      expect(response).to render_template('apo/register_collection')
      expect(response.body).to eq ''
    end

    it 'should create a collection via catkey' do
      catkey = '1234567'
      expect(Dor::RegistrationService).to receive(:create_from_request) do |params|
        expect(params).to match a_hash_including(
          :label           => ':auto',
          :object_type     => 'collection',
          :admin_policy    => @apo.pid,
          :other_id        => 'symphony:' + catkey,
          :metadata_source => 'symphony',
          :rights          => 'dark'
        )
        { :pid => @collection.pid }
      end

      post :register_collection, 'label' => ':auto', 'collection_catkey' => catkey, 'collection_rights_catkey' => 'dark', 'id' => @apo.pid
      expect(response).to have_http_status(:found) # redirects to catalog page
    end

    it 'should create a collection from title/abstract by registering the collection, then adding the abstract' do
      title = 'collection title'
      abstract = 'this is the abstract'
      mock_desc_md_ds = double(Dor::DescMetadataDS)
      expect(mock_desc_md_ds).to receive(:abstract=).with(abstract)
      expect(mock_desc_md_ds).to receive(:ng_xml)
      expect(mock_desc_md_ds).to receive(:content=)
      expect(mock_desc_md_ds).to receive(:save)

      expect(Dor::RegistrationService).to receive(:create_from_request) do |params|
        expect(params).to match a_hash_including(
          :label           => title,
          :object_type     => 'collection',
          :admin_policy    => @apo.pid,
          :metadata_source => 'label',
          :rights          => 'dark'
        )
        { :pid => @collection.pid }
      end
      expect(@collection).to receive(:descMetadata).and_return(mock_desc_md_ds).exactly(4).times

      post :register_collection, 'collection_title' => title, 'collection_abstract' => abstract, 'collection_rights' => 'dark', 'id' => @apo.pid
      expect(response).to have_http_status(:found) # redirects to catalog page
    end

    it 'should add the collection to the apo default collection list' do
      title = 'collection title'
      abstract = 'this is the abstract'
      expect(Dor::RegistrationService).to receive(:create_from_request) do |params|
        expect(params).to match a_hash_including(
          :label           => title,
          :object_type     => 'collection',
          :admin_policy    => @apo.pid,
          :metadata_source => 'label',
          :rights          => 'dark'
        )
        { :pid => @collection.pid }
      end
      expect(controller).to receive(:set_abstract)
      expect(@apo).to receive(:add_default_collection).with(@collection.pid)

      post :register_collection, 'collection_title' => title, 'collection_abstract' => abstract, 'collection_rights' => 'dark', 'id' => @apo.pid
      expect(response).to have_http_status(:found) # redirects to catalog page
    end
  end

  describe 'spreadsheet_template' do
    it 'calls the correct URL' do
      expect(RestClient).to receive(:get).with(Settings.SPREADSHEET_URL)
      get 'spreadsheet_template', :id => @apo.pid
    end
  end

  describe 'overly literal tests' do
    before :each do
      expect(Dor).to receive(:find).with(@apo.pid).and_return @apo
    end
    describe 'add_roleplayer' do
      it 'adds a roleplayer' do
        expect(@apo).to receive(:add_roleplayer)
        post 'add_roleplayer', :id => @apo.pid, :role => 'dor-apo-viewer', :roleplayer => 'Jon'
      end
    end
    describe 'delete_role' do
      it 'calls delete_role' do
        expect(@apo).to receive(:delete_role)
        post 'delete_role', :id => @apo.pid, :role => 'dor-apo-viewer', :entity => 'Jon'
      end
    end
    describe 'delete_collection' do
      it 'calls remove_default_collection' do
        expect(@apo).to receive(:remove_default_collection)
        post 'delete_collection', :id => @apo.pid, :collection => @collection.pid
      end
    end
    describe 'add_collection' do
      it 'calls add_default_collection' do
        expect(@apo).to receive(:add_default_collection)
        post 'add_collection', :id => @apo.pid, :collection => @collection.pid
      end
    end
    describe 'update_title' do
      it 'calls set_title' do
        expect(@apo).to receive(:mods_title=)
        post 'update_title', :id => @apo.pid, :title => 'awesome new title'
      end
    end
    describe 'update_creative_commons' do
      it 'should set creative_commons' do
        expect(@apo).to receive(:creative_commons_license=)
        expect(@apo).to receive(:creative_commons_license_human=)
        post 'update_creative_commons', :id => @apo.pid, :cc_license => 'by-nc'
      end
    end
    describe 'update_use' do
      it 'calls set_use_statement' do
        expect(@apo).to receive(:use_statement=)
        post 'update_use', :id => @apo.pid, :use => 'new use statement'
      end
    end
    describe 'update_copyight' do
      it 'calls set_copyright_statement' do
        expect(@apo).to receive(:copyright_statement=)
        post 'update_copyright', :id => @apo.pid, :copyright => 'new copyright statement'
      end
    end
    describe 'update_default_object_rights' do
      it 'calls set_default_rights' do
        expect(@apo).to receive(:default_rights=)
        post 'update_default_object_rights', :id => @apo.pid, :rights => 'stanford'
      end
    end
    describe 'update_desc_metadata' do
      it 'calls set_desc_metadata_format' do
        expect(@apo).to receive(:desc_metadata_format=)
        post 'update_desc_metadata', :id => @apo.pid, :desc_md => 'TEI'
      end
    end
  end
end
