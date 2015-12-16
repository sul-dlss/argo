# encoding: UTF-8

require 'spec_helper'

describe User, :type => :model do
  describe '.find_or_create_by_webauth' do
    it 'should work' do
      mock_webauth = double('webauth', :login => 'asdf')
      user = User.find_or_create_by_webauth(mock_webauth)
      expect(user.webauth).to eq(mock_webauth)
    end
  end

  context 'with webauth' do
    subject { User.find_or_create_by_webauth(double('webauth', :login => 'mods', :attributes => { 'DISPLAYNAME' => 'Møds Ässet'})) }

    describe '#login' do
      it 'should get the sunetid from Webauth' do
        expect(subject.login).to eq('mods')
      end
    end
    describe '#to_s' do
      it 'should be the name from Webauth' do
        expect(subject.to_s).to eq('Møds Ässet')
      end
    end
  end

  context 'with REMOTE_USER' do
    subject { User.find_or_create_by_remoteuser('mods') }

    describe '#login' do
      it 'should get the username for remoteuser' do
        expect(subject.login).to eq('mods')
      end
    end
    describe '#to_s' do
      it 'should be the name from remoteuser' do
        expect(subject.to_s).to eq('mods')
      end
    end
  end

  describe 'is_admin' do
    it 'should be true if the group is an admin group' do
      allow(subject).to receive(:groups).and_return(['workgroup:sdr:administrator-role'])
      expect(subject.is_admin).to be_truthy
    end
    it 'should be true if the group is a deprecated admin group' do
      allow(subject).to receive(:groups).and_return(['workgroup:dlss:dor-admin'])
      expect(subject.is_admin).to be_truthy
    end
    it 'should be false otherwise' do
      allow(subject).to receive(:groups).and_return([])
      expect(subject.is_admin).to be_falsey
    end
    it 'should be false even with an inadequate group membership' do
      allow(subject).to receive(:groups).and_return(['workgroup:dlss:not_an_admin'])
      expect(subject.is_admin).to be_falsey
      expect(subject.is_admin?).to be_falsey
    end
  end

  describe 'is_manager' do
    it 'should be true if the group is a manager group' do
      allow(subject).to receive(:groups).and_return(['workgroup:sdr:manager-role'])
      expect(subject.is_manager).to be_truthy
    end
    it 'should be true if the group is a deprecated manager group' do
      allow(subject).to receive(:groups).and_return(['workgroup:dlss:dor-manager'])
      expect(subject.is_manager).to be_truthy
    end
    it 'should be false otherwise' do
      allow(subject).to receive(:groups).and_return([])
      expect(subject.is_manager).to be_falsey
      expect(subject.is_manager?).to be_falsey
    end
  end

  describe 'is_viewer' do
    it 'should be true if the group is a viewer group' do
      allow(subject).to receive(:groups).and_return(['workgroup:sdr:viewer-role'])
      expect(subject.is_viewer).to be_truthy
    end
    it 'should be true if the group is a deprecated viewer group' do
      allow(subject).to receive(:groups).and_return(['workgroup:dlss:dor-viewer'])
      expect(subject.is_viewer).to be_truthy
    end
    it 'should be false otherwise' do
      allow(subject).to receive(:groups).and_return([])
      expect(subject.is_viewer).to be_falsey
      expect(subject.is_viewer?).to be_falsey
    end
  end

  describe 'roles' do
    before(:each) do
      @answer = {}
      @doc = {
        'apo_role_dor-administrator_ssim' => ['dlss:groupA', 'dlss:groupB'],
        'apo_role_sdr-administrator_ssim' => ['dlss:groupA', 'dlss:groupB'],
        'apo_role_dor-apo-manager_ssim'   => ['dlss:groupC', 'dlss:groupD'],
        'apo_role_dor-viewer_ssim'        => ['dlss:groupE', 'dlss:groupF'],
        'apo_role_sdr-viewer_ssim'        => ['dlss:groupE', 'dlss:groupF'],
        'apo_role_person_dor-viewer_ssim' => ['sunetid:tcramer'],
        'apo_role_person_sdr-viewer_ssim' => ['sunetid:tcramer'],
        'apo_role_group_manager_ssim'     => ['dlss:groupR']
      }
      @answer['response'] = { 'docs' => [@doc] }
      allow(Dor::SearchService).to receive(:query).and_return(@answer)
      @user = User.find_or_create_by_webauth(double('webauth', :login => 'asdf'))
    end
    it 'should build a set of roles' do
      expect(@user).to receive(:groups).and_return(['dlss:groupF', 'dlss:groupA'])
      expect(@user.roles('pid')).to eq(['dor-administrator', 'sdr-administrator', 'dor-viewer', 'sdr-viewer'])
    end
    it 'should translate the old "manager" role into dor-apo-manager' do
      expect(@user).to receive(:groups).and_return(['dlss:groupR'])
      expect(@user.roles('pid')).to eq(['dor-apo-manager'])
    end
    it 'should work correctly if the individual is named in the apo, but isnt in any groups that matter' do
      expect(@user).to receive(:groups).and_return(['sunetid:tcramer'])
      expect(@user.roles('pid')).to eq(['dor-viewer', 'sdr-viewer'])
    end
    it 'should hang onto results through the life of the user object, avoiding multiple solr searches to find the roles for the same pid multiple times' do
      expect(@user).to receive(:groups).and_return(['sunetid:tcramer'])
      expect(Dor::SearchService).to receive(:query).once
      @user.roles('pid')
      @user.roles('pid')
    end
  end

  describe 'groups' do
    context 'specified' do
      before :each do
        @webauth_privgroup_str = 'dlss:testgroup1|dlss:testgroup2|dlss:testgroup3'
        @user = User.find_or_create_by_webauth(double('webauth', :login => 'asdf', :logged_in? => true, :privgroup => @webauth_privgroup_str))
      end
      it 'should return the groups by webauth' do
        expected_groups = ['sunetid:asdf'] + @webauth_privgroup_str.split(/\|/).map { |g| "workgroup:#{g}" }
        expect(@user.groups).to eq(expected_groups)
      end
      it 'should return the groups by impersonation' do
        impersonated_groups = ['workgroup:dlss:impersonatedgroup1', 'workgroup:dlss:impersonatedgroup2']
        @user.set_groups_to_impersonate(impersonated_groups)
        expect(@user.groups).to eq(impersonated_groups)
      end
    end
    it "should return false for is_admin/is_manager/is_viewer if such groups aren't specified for impersonation, even if the user is part of the admin/manager/viewer groups" do
      webauth_privgroup_str = 'sdr:administrator-role|sdr:manager-role|sdr:viewer-role'
      mock_webauth = double('webauth', :login => 'asdf', :logged_in? => true, :privgroup => webauth_privgroup_str)
      user = User.find_or_create_by_webauth(mock_webauth)
      expect(user.is_admin  ).to be_truthy
      expect(user.is_manager).to be_truthy
      expect(user.is_viewer ).to be_truthy
      user.set_groups_to_impersonate(['workgroup:sdr:not-an-administrator-role', 'workgroup:sdr:not-a-manager-role', 'workgroup:sdr:not-a-viewer-role'])
      expect(user.is_admin  ).to be_falsey
      expect(user.is_manager).to be_falsey
      expect(user.is_viewer ).to be_falsey
    end
  end
  describe '#can_view_something?' do
    it 'returns false' do
      expect(subject.can_view_something?).to be_falsey
    end
    context 'when admin' do
      it 'returns true' do
        expect(subject).to receive(:is_admin).and_return(true)
        expect(subject.can_view_something?).to be_truthy
      end
    end
    context 'when manager' do
      it 'returns true' do
        expect(subject).to receive(:is_admin).and_return(false)
        expect(subject).to receive(:is_manager).and_return(true)
        expect(subject.can_view_something?).to be_truthy
      end
    end
    context 'when viewer' do
      it 'returns true' do
        expect(subject).to receive(:is_admin).and_return(false)
        expect(subject).to receive(:is_manager).and_return(false)
        expect(subject).to receive(:is_viewer).and_return(true)
        expect(subject.can_view_something?).to be_truthy
      end
    end
    context 'with permitted_apos' do
      it 'returns true' do
        expect(subject).to receive(:is_admin).and_return(false)
        expect(subject).to receive(:is_manager).and_return(false)
        expect(subject).to receive(:is_viewer).and_return(false)
        expect(subject).to receive(:permitted_apos).and_return([1])
        expect(subject.can_view_something?).to be_truthy
      end
    end
  end

  # TODO
  describe 'permitted_apos' do
    xit 'not implemented' do
    end
  end
  describe 'permitted_collections' do
    xit 'not implemented' do
    end
  end
end
