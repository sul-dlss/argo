require 'spec_helper'

class TestClass
  include Argo::AccessControlsEnforcement
end

describe 'Argo::AccessControlsEnforcement' do
  before :each do
    @obj=TestClass.new
  end
  describe 'apply_gated_discovery' do
    it 'should add a fq that requires the apo' do
      user=mock(User)
      user.stub(:permitted_apos).and_return(['druid:cb081vd1895'])
      solr_params={}
      @obj.apply_gated_discovery(solr_params,user)
      solr_params.should == {:fq=>["is_governed_by_s:(info\\:fedora/druid\\:cb081vd1895)"]}
    end
    it 'should add to an existing fq' do
      user=mock(User)
      user.stub(:permitted_apos).and_return(['druid:cb081vd1895'])
      solr_params={:fq=>["is_governed_by_s:(info\\:fedora/druid\\:ab123cd4567)"]}
      @obj.apply_gated_discovery(solr_params,user)
      solr_params.should == {:fq=>["is_governed_by_s:(info\\:fedora/druid\\:ab123cd4567)", "is_governed_by_s:(info\\:fedora/druid\\:cb081vd1895)"]}
    end
    it 'should build a valid query if there arent any apos' do
      user=mock(User)
      user.stub(:permitted_apos).and_return([])
      solr_params={}
      @obj.apply_gated_discovery(solr_params,user)
      solr_params.should == {:fq=>["is_governed_by_s:(dummy_value)"]}
    end
  end
end