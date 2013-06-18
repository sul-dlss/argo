require 'spec_helper'

describe 'mods_view' do
  before :each do
    @object = instantiate_fixture("druid_zt570tx3016", Dor::Item)
    Dor::Item.stub(:find).and_return(@object)
  end
  it' should render the mods view including a title' do
    visit '/items/druid:zt570tx3016/purl_preview'
    page.should have_content('Ampex')
  end
end