require 'spec_helper'
describe ApoController do

  before :each do
    @item = instantiate_fixture("druid_zt570tx3016", Dor::AdminPolicyObject)
    @item.stub(:save)
    @item.stub(:update_index)
    @empty_item = instantiate_fixture("pw570tx3016", Dor::AdminPolicyObject)
    @empty_item.stub(:save)
    @empty_item.stub(:update_index)
    log_in_as_mock_user(subject)

  end
  describe 'add_roleplayer' do
    it 'adds a roleplayer' do
      Dor.should_receive(:find).and_return @item
      @item.should_receive(:add_roleplayer)
      post 'add_roleplayer', :id => 'druid_zt570tx3016', :role => 'dor-apo-viewer', :roleplayer => 'Jon'
    end
  end
  describe 'delete_role' do
    it 'calls delete_role ' do
      Dor.should_receive(:find).and_return @item
      @item.should_receive(:delete_role)
      post 'delete_role', :id => 'druid_zt570tx3016', :role => 'dor-apo-viewer', :entity => 'Jon'
    end
  end
  describe 'delete_collection' do
    it 'calls remove_default_collection ' do
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
      @item.should_receive(:creative_commons=)
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