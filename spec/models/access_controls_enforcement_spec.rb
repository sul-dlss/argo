require 'spec_helper'

class TestClass
  include Argo::AccessControlsEnforcement
end

describe 'Argo::AccessControlsEnforcement', :type => :model do
  before :each do
    @obj=TestClass.new
    @user=double(@user)
    allow(@user).to receive(:is_manager).and_return(false)
    allow(@user).to receive(:is_admin).and_return(false)
    allow(@user).to receive(:is_viewer).and_return(false)
  end
  describe 'apply_gated_discovery' do
    it 'should add a fq that requires the apo' do
      allow(@user).to receive(:permitted_apos).and_return(['druid:cb081vd1895'])
      solr_params={}
      @obj.apply_gated_discovery(solr_params,@user)
      expect(solr_params).to eq({:fq => ["is_governed_by_s:(\"info:fedora/druid:cb081vd1895\")"]})
    end
    it 'should add to an existing fq' do
      allow(@user).to receive(:permitted_apos).and_return(['druid:cb081vd1895'])
      solr_params={:fq=>["is_governed_by_s:(info\\:fedora/druid\\:ab123cd4567)"]}
      @obj.apply_gated_discovery(solr_params,@user)
      expect(solr_params).to eq({:fq=>["is_governed_by_s:(info\\:fedora/druid\\:ab123cd4567)", "is_governed_by_s:(\"info:fedora/druid:cb081vd1895\")"]})
    end
    it 'should build a valid query if there arent any apos' do
      allow(@user).to receive(:permitted_apos).and_return([])
      solr_params={}
      @obj.apply_gated_discovery(solr_params,@user)
      expect(solr_params).to eq({:fq=>["is_governed_by_s:(dummy_value)"]})
    end
    it 'should return no fq if the @user is a repository admin' do
      allow(@user).to receive(:permitted_apos).and_return([])
      allow(@user).to receive(:is_admin).and_return(true)
      solr_params={}
      @obj.apply_gated_discovery(solr_params,@user)
      expect(solr_params).to eq({})
    end
    it 'should return no fq if the @user is a repository viewer' do
      allow(@user).to receive(:permitted_apos).and_return([])
      allow(@user).to receive(:is_viewer).and_return(true)
      solr_params={}
      @obj.apply_gated_discovery(solr_params,@user)
      expect(solr_params).to eq({})
    end
  end
end
