# encoding: UTF-8

require 'spec_helper'

describe User do
  describe '.find_or_create_by_webauth' do
    it "should work" do
      mock_webauth = double('webauth', :login => 'asdf')
      user = User.find_or_create_by_webauth(mock_webauth)
      user.webauth.should == mock_webauth
    end
  end

  context "with webauth" do
    subject { User.find_or_create_by_webauth(double('webauth', :login => 'mods', :attributes => { 'DISPLAYNAME' => 'Møds Ässet'})) }

    describe "#login" do
      it "should get the sunetid from Webauth" do
        subject.login.should == 'mods'
      end
    end
    describe "#to_s" do
      it "should be the name from Webauth" do
        subject.to_s.should == 'Møds Ässet'
      end
    end
  end

  context "with REMOTE_USER" do
    subject { User.find_or_create_by_remoteuser('mods') }

    describe "#login" do
      it "should get the username for remoteuser" do
        subject.login.should == 'mods'
      end
    end
    describe "#to_s" do
      it "should be the name from remoteuser" do
        subject.to_s.should == 'mods'
      end
    end
  end

  describe "is_admin" do
    it 'should be true if the group is an admin group' do
      subject.stub(:groups).and_return(['workgroup:sdr:administrator-role'])
      subject.is_admin.should == true
    end
    it 'should be true if the group is a deprecated admin group' do
      subject.stub(:groups).and_return(['workgroup:dlss:dor-admin'])
      subject.is_admin.should == true
    end
  end

  describe "is_manager" do
    it 'should be true if the group is a manager group' do
      subject.stub(:groups).and_return(['workgroup:sdr:manager-role'])
      subject.is_manager.should == true
    end
    it 'should be true if the group is a deprecated manager group' do
      subject.stub(:groups).and_return(['workgroup:dlss:dor-manager'])
      subject.is_manager.should == true
    end
  end

  describe 'is_viewer' do
    it 'should be true if the group is a viewer group' do
      subject.stub(:groups).and_return(['workgroup:sdr:viewer-role'])
      subject.is_viewer.should == true
    end
    it 'should be true if the group is a deprecated viewer group' do
      subject.stub(:groups).and_return(['workgroup:dlss:dor-viewer'])
      subject.is_viewer.should == true
    end
  end

  describe 'roles' do
    before(:each) do
      @answer={}
      @answer['response']={}
      @answer['response']['docs']=[]
      @doc={}
      @doc['apo_role_dor-administrator_t']=['dlss:groupA', 'dlss:groupB']
      @doc['apo_role_sdr-administrator_t']=['dlss:groupA', 'dlss:groupB']
      @doc['apo_role_dor-apo-manager_t']=['dlss:groupC', 'dlss:groupD']
      @doc['apo_role_dor-viewer_t']=['dlss:groupE', 'dlss:groupF']
      @doc['apo_role_sdr-viewer_t']=['dlss:groupE', 'dlss:groupF']
      @doc['apo_role_person_dor-viewer_t']=['sunetid:tcramer']
      @doc['apo_role_person_sdr-viewer_t']=['sunetid:tcramer']
      @doc['apo_role_group_manager_t']=['dlss:groupR']
      @answer['response']['docs'] << @doc
      Dor::SearchService.stub(:query).and_return(@answer)
    end
    it 'should build a set of roles' do
      User.any_instance.stub(:groups).and_return(['dlss:groupF', 'dlss:groupA'])
      mock_webauth = double('webauth', :login => 'asdf')
      user = User.find_or_create_by_webauth(mock_webauth)
      res=user.roles('pid')
      res.should == ['dor-administrator', 'sdr-administrator', 'dor-viewer', 'sdr-viewer']
    end
    it 'should translate the old "manager" role into dor-apo-manager' do
      User.any_instance.stub(:groups).and_return(['dlss:groupR'])
      mock_webauth = double('webauth', :login => 'asdf')
      user = User.find_or_create_by_webauth(mock_webauth)
      res=user.roles('pid')
      res.should == ['dor-apo-manager']
    end
    it 'should work correctly if the individual is named in the apo, but isnt in any groups that matter' do
      User.any_instance.stub(:groups).and_return(['sunetid:tcramer'])
      mock_webauth = double('webauth', :login => 'asdf')
      user = User.find_or_create_by_webauth(mock_webauth)
      res=user.roles('pid')
      res.should == ['dor-viewer', 'sdr-viewer']
    end
    it 'should hang onto results through the life of the user object, avoiding multiple solr searches to find the roles for the same pid multiple times' do
      User.any_instance.stub(:groups).and_return(['sunetid:tcramer'])
      mock_webauth = double('webauth', :login => 'asdf')
      user = User.find_or_create_by_webauth(mock_webauth)
      Dor::SearchService.should_receive(:query).once
      res=user.roles('pid')
      res=user.roles('pid')
    end
  end

  describe "groups" do
    it "should return the groups specified by webauth" do
      webauth_privgroup_str = "dlss:testgroup1|dlss:testgroup2|dlss:testgroup3"
      sunetid = 'asdf'
      mock_webauth = double('webauth', :login => sunetid, :logged_in? => true, :privgroup => webauth_privgroup_str)

      user = User.find_or_create_by_webauth(mock_webauth)

      expected_groups = ["sunetid:#{sunetid}"] + webauth_privgroup_str.split(/\|/).collect { |g| "workgroup:#{g}" }
      expect(user.groups).to eq(expected_groups)
    end
    it "should return the groups specified for impersonation" do
      webauth_privgroup_str = "dlss:testgroup1|dlss:testgroup2|dlss:testgroup3"
      sunetid = 'asdf'
      mock_webauth = double('webauth', :login => sunetid, :logged_in? => true, :privgroup => webauth_privgroup_str)

      user = User.find_or_create_by_webauth(mock_webauth)
      impersonated_groups = ["workgroup:dlss:impersonatedgroup1", "workgroup:dlss:impersonatedgroup2"]
      user.set_groups_to_impersonate(impersonated_groups)
      
      expect(user.groups).to eq(impersonated_groups)
    end
  end

  #TODO
  describe 'permitted_apos' do
  end
  describe 'permitted_collections' do
  end
end
