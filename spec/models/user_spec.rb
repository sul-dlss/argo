# encoding: UTF-8

require 'spec_helper'

describe User, :type => :model do
  describe '.find_or_create_by_webauth' do
    it "should work" do
      mock_webauth = double('webauth', :login => 'asdf')
      user = User.find_or_create_by_webauth(mock_webauth)
      expect(user.webauth).to eq(mock_webauth)
    end
  end

  context "with webauth" do
    subject { User.find_or_create_by_webauth(double('webauth', :login => 'mods', :attributes => { 'DISPLAYNAME' => 'Møds Ässet'})) }

    describe "#login" do
      it "should get the sunetid from Webauth" do
        expect(subject.login).to eq('mods')
      end
    end
    describe "#to_s" do
      it "should be the name from Webauth" do
        expect(subject.to_s).to eq('Møds Ässet')
      end
    end
  end

  context "with REMOTE_USER" do
    subject { User.find_or_create_by_remoteuser('mods') }

    describe "#login" do
      it "should get the username for remoteuser" do
        expect(subject.login).to eq('mods')
      end
    end
    describe "#to_s" do
      it "should be the name from remoteuser" do
        expect(subject.to_s).to eq('mods')
      end
    end
  end

  describe "is_admin" do
    it 'should be true if the group is an admin group' do
      allow(subject).to receive(:groups).and_return(['workgroup:sdr:administrator-role'])
      expect(subject.is_admin).to eq(true)
    end
    it 'should be true if the group is a deprecated admin group' do
      allow(subject).to receive(:groups).and_return(['workgroup:dlss:dor-admin'])
      expect(subject.is_admin).to eq(true)
    end
    it 'should be false otherwise' do
      allow(subject).to receive(:groups).and_return([])
      expect(subject.is_admin).to eq(false)
      expect(subject.is_admin?).to eq(false)
    end
  end

  describe "is_manager" do
    it 'should be true if the group is a manager group' do
      allow(subject).to receive(:groups).and_return(['workgroup:sdr:manager-role'])
      expect(subject.is_manager).to eq(true)
    end
    it 'should be true if the group is a deprecated manager group' do
      allow(subject).to receive(:groups).and_return(['workgroup:dlss:dor-manager'])
      expect(subject.is_manager).to eq(true)
    end
    it 'should be false otherwise' do
      allow(subject).to receive(:groups).and_return([])
      expect(subject.is_manager).to eq(false)
      expect(subject.is_manager?).to eq(false)
    end
  end

  describe 'is_viewer' do
    it 'should be true if the group is a viewer group' do
      allow(subject).to receive(:groups).and_return(['workgroup:sdr:viewer-role'])
      expect(subject.is_viewer).to eq(true)
    end
    it 'should be true if the group is a deprecated viewer group' do
      allow(subject).to receive(:groups).and_return(['workgroup:dlss:dor-viewer'])
      expect(subject.is_viewer).to eq(true)
    end
    it 'should be false otherwise' do
      allow(subject).to receive(:groups).and_return([])
      expect(subject.is_viewer).to eq(false)
      expect(subject.is_viewer?).to eq(false)
    end
  end

  describe 'roles' do
    before(:each) do
      @answer={}
      @doc={}
      @doc['apo_role_dor-administrator_t']=['dlss:groupA', 'dlss:groupB']
      @doc['apo_role_sdr-administrator_t']=['dlss:groupA', 'dlss:groupB']
      @doc['apo_role_dor-apo-manager_t']=['dlss:groupC', 'dlss:groupD']
      @doc['apo_role_dor-viewer_t']=['dlss:groupE', 'dlss:groupF']
      @doc['apo_role_sdr-viewer_t']=['dlss:groupE', 'dlss:groupF']
      @doc['apo_role_person_dor-viewer_t']=['sunetid:tcramer']
      @doc['apo_role_person_sdr-viewer_t']=['sunetid:tcramer']
      @doc['apo_role_group_manager_t']=['dlss:groupR']
      @answer['response'] = {'docs' => [@doc]}
      allow(Dor::SearchService).to receive(:query).and_return(@answer)
    end
    it 'should build a set of roles' do
      allow_any_instance_of(User).to receive(:groups).and_return(['dlss:groupF', 'dlss:groupA'])
      mock_webauth = double('webauth', :login => 'asdf')
      user = User.find_or_create_by_webauth(mock_webauth)
      res=user.roles('pid')
      expect(res).to eq(['dor-administrator', 'sdr-administrator', 'dor-viewer', 'sdr-viewer'])
    end
    it 'should translate the old "manager" role into dor-apo-manager' do
      allow_any_instance_of(User).to receive(:groups).and_return(['dlss:groupR'])
      mock_webauth = double('webauth', :login => 'asdf')
      user = User.find_or_create_by_webauth(mock_webauth)
      res=user.roles('pid')
      expect(res).to eq(['dor-apo-manager'])
    end
    it 'should work correctly if the individual is named in the apo, but isnt in any groups that matter' do
      allow_any_instance_of(User).to receive(:groups).and_return(['sunetid:tcramer'])
      mock_webauth = double('webauth', :login => 'asdf')
      user = User.find_or_create_by_webauth(mock_webauth)
      res=user.roles('pid')
      expect(res).to eq(['dor-viewer', 'sdr-viewer'])
    end
    it 'should hang onto results through the life of the user object, avoiding multiple solr searches to find the roles for the same pid multiple times' do
      allow_any_instance_of(User).to receive(:groups).and_return(['sunetid:tcramer'])
      mock_webauth = double('webauth', :login => 'asdf')
      user = User.find_or_create_by_webauth(mock_webauth)
      expect(Dor::SearchService).to receive(:query).once
      res=user.roles('pid')
      res=user.roles('pid')
    end
  end

  describe "groups" do
    it "should return the groups specified by webauth" do
      webauth_privgroup_str = "dlss:testgroup1|dlss:testgroup2|dlss:testgroup3"
      mock_webauth = double('webauth', :login => 'asdf', :logged_in? => true, :privgroup => webauth_privgroup_str)

      user = User.find_or_create_by_webauth(mock_webauth)
      expected_groups = ["sunetid:asdf"] + webauth_privgroup_str.split(/\|/).collect { |g| "workgroup:#{g}" }
      expect(user.groups).to eq(expected_groups)
    end
    it "should return the groups specified for impersonation" do
      webauth_privgroup_str = "dlss:testgroup1|dlss:testgroup2|dlss:testgroup3"
      mock_webauth = double('webauth', :login => 'asdf', :logged_in? => true, :privgroup => webauth_privgroup_str)
      user = User.find_or_create_by_webauth(mock_webauth)
      impersonated_groups = ["workgroup:dlss:impersonatedgroup1", "workgroup:dlss:impersonatedgroup2"]
      user.set_groups_to_impersonate(impersonated_groups)
      expect(user.groups).to eq(impersonated_groups)
    end
    it "should return false for is_admin/is_manager/is_viewer if such groups aren't specified for impersonation, even if the user is part of the admin/manager/viewer groups" do
      webauth_privgroup_str = "sdr:administrator-role|sdr:manager-role|sdr:viewer-role"
      mock_webauth = double('webauth', :login => 'asdf', :logged_in? => true, :privgroup => webauth_privgroup_str)
      user = User.find_or_create_by_webauth(mock_webauth)
      expect(user.is_admin  ).to eq(true)
      expect(user.is_manager).to eq(true)
      expect(user.is_viewer ).to eq(true)

      user.set_groups_to_impersonate(['workgroup:sdr:not-an-administrator-role', 'workgroup:sdr:not-a-manager-role', 'workgroup:sdr:not-a-viewer-role'])
      expect(user.is_admin  ).to eq(false)
      expect(user.is_manager).to eq(false)
      expect(user.is_viewer ).to eq(false)
    end
  end

  #TODO
  describe 'permitted_apos' do
    xit "not implemented" do
    end
  end
  describe 'permitted_collections' do
    xit "not implemented" do
    end
  end
end
