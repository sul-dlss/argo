require 'spec_helper'

describe 'mods_view' do
  before :each do
    @object = instantiate_fixture("druid_zt570tx3016", Dor::Item)
    Dor::Item.stub(:find).and_return(@object)
    @current_user=double(:webauth_user, :login => 'sunetid', :logged_in? => true,:privgroup=>ADMIN_GROUPS.first)
    @current_user.stub(:is_admin).and_return(true)
    @current_user.stub(:roles).and_return([])
    @current_user.stub(:is_manager).and_return(false)
    ItemsController.any_instance.stub(:current_user).and_return(@current_user)
  end
  context "main page tests" do
    it 'should have the expected heading for search facets' do
      visit root_path
      page.should have_content('Limit your search')
    end
    it 'should have the expected search facets' do
      search_facets = ['Object Type', 'Content Type', 'Admin. Policy', 'Lifecycle', 'Workflows (WPS)', 'Version']
      visit root_path
      search_facets.each do |facet|
        page.should have_content(facet)
      end
    end
  end
  context 'mods view' do
    it' should render the mods view including a title' do
      visit '/items/druid:zt570tx3016/purl_preview'
      page.should have_content('Ampex')
    end
  end
  context 'item dialogs' do
    context 'open version ui' do
      it' should render the open version ui' do
        visit '/items/druid:zt570tx3016/open_version_ui'
        page.should have_content('description')
      end
    end
    context 'close version ui' do
      it' should render the open version ui' do
        visit '/items/druid:zt570tx3016/close_version_ui'
        page.should have_content('description')
      end
    end
    context 'add workflow' do
      it' should render the add workflow ui' do
        visit '/items/druid:zt570tx3016/add_workflow'
        page.should have_content('Add Workflow')
      end
    end
    context 'open version ui' do
      it' should render the add collection ui' do
        @current_user.stub(:permitted_collections).and_return(['druid:ab123cd4567'])
        visit '/items/druid:zt570tx3016/collection_ui'
        page.should have_content('Add Collection')
      end
    end
    context 'content type' do
      it' should render the edit content type ui' do
        visit '/items/druid:zt570tx3016/content_type'
        page.should have_content('Content type')
      end
    end
    context 'embargo form' do
      it' should render the embargo update ui' do
        visit '/items/druid:zt570tx3016/embargo_form'
        page.should have_content('Embargo')
      end
    end
    context 'mods' do
      it' should render the mods editor' do
        visit '/items/druid:zt570tx3016/mods'
        #there isnt anything on the mods editor page, it is all loaded via js...
        page.status_code.should == 200
      end
    end
    context 'rights form' do
      it' should render the access rights update ui' do
        visit '/items/druid:zt570tx3016/rights'
        page.should have_content('dark')
      end
    end
    context 'source id ui' do
      it' should render the source id update ui' do
        idmd=double(Dor::IdentityMetadataDS)
        @object.stub(:identityMetadata).and_return(idmd)
        idmd.stub(:sourceId).and_return('something123')
        visit '/items/druid:zt570tx3016/source_id_ui'
        page.should have_content('Update')
      end
    end
    context 'tag ui' do
      it' should render the source id update ui' do
        idmd=double(Dor::IdentityMetadataDS)
        Dor::Item.stub(:identityMetadata).and_return(idmd)
        idmd.stub(:tags).and_return(['something:123'])
        visit '/items/druid:zt570tx3016/tags_ui'
        page.should have_content('Update tags')
      end
    end
  end
end