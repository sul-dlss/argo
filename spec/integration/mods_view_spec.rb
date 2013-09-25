require 'spec_helper'

describe 'mods_view' do
  before :each do
    @object = instantiate_fixture("druid_zt570tx3016", Dor::Item)
    Dor::Item.stub(:find).and_return(@object)
    @current_user=mock(:webauth_user, :login => 'sunetid', :logged_in? => true,:privgroup=>ADMIN_GROUPS.first)
    @current_user.stub(:is_admin).and_return(true)
    @current_user.stub(:roles).and_return([])
    @current_user.stub(:is_manager).and_return(false)
    ItemsController.any_instance.stub(:current_user).and_return(@current_user)
  end

  it' should render the mods view including a title' do
    visit '/items/druid:zt570tx3016/purl_preview'
    page.should have_content('Ampex')
  end
end