require 'spec_helper'

# General documentation about roles and permissions is on SUL Consul at
# https://consul.stanford.edu/display/chimera/Repository+Roles+and+Permissions

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

  describe 'is_admin?' do
    it 'should be true if the group is an admin group' do
      allow(subject).to receive(:groups).and_return(['workgroup:sdr:administrator-role'])
      expect(subject.is_admin?).to be true
    end
    it 'should be false if the group is a deprecated admin group' do
      allow(subject).to receive(:groups).and_return(['workgroup:dlss:dor-admin'])
      expect(subject.is_admin?).to be false
    end
    it 'should be false for a blank group' do
      allow(subject).to receive(:groups).and_return([])
      expect(subject.is_admin?).to be false
      allow(subject).to receive(:groups).and_return(nil)
      expect(subject.is_admin?).to be false
    end
    it 'should be false with an inadequate group membership' do
      allow(subject).to receive(:groups).and_return(['workgroup:dlss:not-admin'])
      expect(subject.is_admin?).to be false
    end
    it 'should be true for ADMIN_GROUPS' do
      allow(subject).to receive(:groups).and_return(User::ADMIN_GROUPS)
      expect(subject.is_admin?).to be true
    end
    it 'should be false for MANAGER_GROUPS' do
      allow(subject).to receive(:groups).and_return(User::MANAGER_GROUPS)
      expect(subject.is_admin?).to be false
    end
    it 'should be false for VIEWER_GROUPS' do
      allow(subject).to receive(:groups).and_return(User::VIEWER_GROUPS)
      expect(subject.is_admin?).to be false
    end
  end

  describe 'is_manager?' do
    it 'should be true if the group is a manager group' do
      allow(subject).to receive(:groups).and_return(['workgroup:sdr:manager-role'])
      expect(subject.is_manager?).to be true
    end
    it 'should be false if the group is a deprecated manager group' do
      allow(subject).to receive(:groups).and_return(['workgroup:dlss:dor-manager'])
      expect(subject.is_manager?).to be false
    end
    it 'should be false for a blank group' do
      allow(subject).to receive(:groups).and_return([])
      expect(subject.is_manager?).to be false
      allow(subject).to receive(:groups).and_return(nil)
      expect(subject.is_manager?).to be false
    end
    it 'should be false with an inadequate group membership' do
      allow(subject).to receive(:groups).and_return(['workgroup:dlss:not-manager'])
      expect(subject.is_manager?).to be false
    end
    it 'should be false for ADMIN_GROUPS' do
      allow(subject).to receive(:groups).and_return(User::ADMIN_GROUPS)
      expect(subject.is_manager?).to be false
    end
    it 'should be true for MANAGER_GROUPS' do
      allow(subject).to receive(:groups).and_return(User::MANAGER_GROUPS)
      expect(subject.is_manager?).to be true
    end
    it 'should be false for VIEWER_GROUPS' do
      allow(subject).to receive(:groups).and_return(User::VIEWER_GROUPS)
      expect(subject.is_manager?).to be false
    end
  end

  describe 'is_viewer?' do
    it 'should be true if the group is a viewer group' do
      allow(subject).to receive(:groups).and_return(['workgroup:sdr:viewer-role'])
      expect(subject.is_viewer?).to be true
    end
    it 'should be false if the group is a deprecated viewer group' do
      allow(subject).to receive(:groups).and_return(['workgroup:dlss:dor-viewer'])
      expect(subject.is_viewer?).to be false
    end
    it 'should be false for a blank group' do
      allow(subject).to receive(:groups).and_return([])
      expect(subject.is_viewer?).to be false
      allow(subject).to receive(:groups).and_return(nil)
      expect(subject.is_viewer?).to be false
    end
    it 'should be false with an inadequate group membership' do
      allow(subject).to receive(:groups).and_return(['workgroup:dlss:not-viewer'])
      expect(subject.is_viewer?).to be false
    end
    it 'should be false for ADMIN_GROUPS' do
      allow(subject).to receive(:groups).and_return(User::ADMIN_GROUPS)
      expect(subject.is_viewer?).to be false
    end
    it 'should be false for MANAGER_GROUPS' do
      allow(subject).to receive(:groups).and_return(User::MANAGER_GROUPS)
      expect(subject.is_viewer?).to be false
    end
    it 'should be true for VIEWER_GROUPS' do
      allow(subject).to receive(:groups).and_return(User::VIEWER_GROUPS)
      expect(subject.is_viewer?).to be true
    end
  end

  describe 'KNOWN_ROLES' do
    it 'contains roles defined in Dor::Governable'
  end

  describe 'solr_role_allowed' do
    let(:solr_doc) do
      {
        'roleA' => ['dlss:groupA', 'dlss:groupB'],
        'roleB' => ['dlss:groupA', 'dlss:groupC']
      }
    end
    before :each do
      allow(subject).to receive(:groups).and_return(['dlss:groupA'])
    end
    it 'returns true when DOR solr document has a role with values that include a user group' do
      expect(subject.solr_role_allowed?(solr_doc, 'roleA')).to be true
    end
    it 'returns false when DOR solr document has a role with values that do not include a user group' do
      allow(subject).to receive(:groups).and_return(['dlss:groupX'])
      expect(subject.solr_role_allowed?(solr_doc, 'roleA')).to be false
    end
    it 'returns false when DOR solr document has no matching roles' do
      expect(subject.solr_role_allowed?(solr_doc, 'roleX')).to be false
    end
    it 'returns false when DOR solr document is empty' do
      expect(subject.solr_role_allowed?({}, 'roleA')).to be false
    end
    it 'returns false when user belongs to no groups' do
      allow(subject).to receive(:groups).and_return([])
      expect(subject.solr_role_allowed?(solr_doc, 'roleA')).to be false
    end
  end

  describe 'roles' do
    # The exact DRUID is not important in these specs, because
    # the Dor::SearchService is mocked to return solr_doc.
    let(:druid) { 'druid:ab123cd4567' }
    let(:answer) do
      {
        'response' => { 'docs' => [solr_doc] }
      }
    end
    let(:solr_doc) do
      {
        'apo_role_sdr-administrator_ssim' => %w(workgroup:dlss:groupA workgroup:dlss:groupB),
        'apo_role_sdr-viewer_ssim'        => %w(workgroup:dlss:groupE workgroup:dlss:groupF),
        'apo_role_dor-apo-manager_ssim'   => %w(workgroup:dlss:groupC workgroup:dlss:groupD),
        'apo_role_person_sdr-viewer_ssim' => %w(sunetid:tcramer),
        'apo_role_group_manager_ssim'     => %w(workgroup:dlss:groupR)
      }
    end
    before(:each) do
      allow(Dor::SearchService).to receive(:query).and_return(answer)
    end
    it 'should accept any object identifier' do
      expect{subject.roles(druid)}.not_to raise_error
      expect{subject.roles('anyStringOK')}.not_to raise_error
    end
    it 'should return an empty array for any blank object identifer' do
      ['', nil].each do |pid|
        expect{subject.roles(pid)}.not_to raise_error
        expect(subject.roles(pid)).to be_empty
      end
    end
    it 'should build a set of roles from groups' do
      user_groups = %w(workgroup:dlss:groupF workgroup:dlss:groupA)
      user_roles = %w(sdr-administrator sdr-viewer)
      expect(subject).to receive(:groups).and_return(user_groups).at_least(:once)
      expect(subject.roles(druid)).to eq(user_roles)
    end
    it 'should translate the old "manager" role into dor-apo-manager' do
      expect(subject).to receive(:groups).and_return(['workgroup:dlss:groupR']).at_least(:once)
      expect(subject.roles(druid)).to eq(['dor-apo-manager'])
    end
    it 'should return an empty set of roles if the DRUID solr search fails' do
      empty_doc = { 'response' => { 'docs' => [] } }
      allow(Dor::SearchService).to receive(:query).and_return(empty_doc)
      # check that the code will return immediately if solr doc is empty
      expect(subject).not_to receive(:groups)
      expect(subject).not_to receive(:solr_role_allowed?)
      expect(subject.roles(druid)).to be_empty
    end
    it 'should work correctly if the individual is named in the apo, but is not in any groups that matter' do
      expect(subject).to receive(:groups).and_return(['sunetid:tcramer']).at_least(:once)
      expect(subject.roles(druid)).to eq(['sdr-viewer'])
    end
    it 'should hang onto results through the life of the user object, avoiding multiple solr searches to find the roles for the same pid multiple times' do
      expect(subject).to receive(:groups).and_return(['testdoesnotcarewhatishere']).at_least(:once)
      expect(Dor::SearchService).to receive(:query).once
      subject.roles(druid)
      subject.roles(druid)
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
        impersonated_groups = %w(workgroup:dlss:impersonatedgroup1 workgroup:dlss:impersonatedgroup2)
        @user.set_groups_to_impersonate(impersonated_groups)
        expect(@user.groups).to eq(impersonated_groups)
      end
    end
    it "should return false for is_admin/is_manager/is_viewer if such groups aren't specified for impersonation, even if the user is part of the admin/manager/viewer groups" do
      webauth_privgroup_str = 'sdr:administrator-role|sdr:manager-role|sdr:viewer-role'
      mock_webauth = double('webauth', :login => 'asdf', :logged_in? => true, :privgroup => webauth_privgroup_str)
      user = User.find_or_create_by_webauth(mock_webauth)
      expect(user.is_admin?).to be true
      expect(user.is_manager?).to be true
      expect(user.is_viewer?).to be true
      user.set_groups_to_impersonate(%w(workgroup:sdr:not-an-administrator-role workgroup:sdr:not-a-manager-role workgroup:sdr:not-a-viewer-role))
      expect(user.is_admin?).to be false
      expect(user.is_manager?).to be false
      expect(user.is_viewer?).to be false
    end
  end

  describe 'set_groups_to_impersonate' do
    def groups_to_impersonate
      subject.instance_variable_get(:@groups_to_impersonate)
    end
    before :each do
      subject.instance_variable_set(:@groups_to_impersonate, %w(a b))
    end
    it 'resets the role_cache' do
      subject.instance_variable_set(:@role_cache, {a: 1})
      subject.set_groups_to_impersonate []
      expect(subject.instance_variable_get(:@role_cache)).to be_empty
    end
    it 'removes impersonation groups when given nil' do
      subject.set_groups_to_impersonate nil
      expect(groups_to_impersonate).to be_nil
    end
    it 'removes impersonation groups when given an empty String' do
      subject.set_groups_to_impersonate ''
      expect(groups_to_impersonate).to be_nil
    end
    it 'removes impersonation groups when given an empty Array' do
      subject.set_groups_to_impersonate []
      expect(groups_to_impersonate).to be_nil
    end
    it 'removes impersonation groups when given an empty Hash' do
      subject.set_groups_to_impersonate({})
      expect(groups_to_impersonate).to be_nil
    end
    it 'returns an Array<String> given a String argument' do
      subject.set_groups_to_impersonate 'groupA'
      expect(groups_to_impersonate).to eq ['groupA']
    end
    it 'returns an Array<String> argument as given' do
      subject.set_groups_to_impersonate ['groupA']
      expect(groups_to_impersonate).to eq ['groupA']
    end
  end

  describe '#can_view_something?' do
    it 'returns false' do
      expect(subject.can_view_something?).to be false
    end
    context 'when admin' do
      it 'returns true' do
        expect(subject).to receive(:is_admin?).and_return(true)
        expect(subject.can_view_something?).to be true
      end
    end
    context 'when manager' do
      it 'returns true' do
        expect(subject).to receive(:is_admin?).and_return(false)
        expect(subject).to receive(:is_manager?).and_return(true)
        expect(subject.can_view_something?).to be true
      end
    end
    context 'when viewer' do
      it 'returns true' do
        expect(subject).to receive(:is_admin?).and_return(false)
        expect(subject).to receive(:is_manager?).and_return(false)
        expect(subject).to receive(:is_viewer?).and_return(true)
        expect(subject.can_view_something?).to be true
      end
    end
    context 'with permitted_apos' do
      it 'returns true' do
        expect(subject).to receive(:is_admin?).and_return(false)
        expect(subject).to receive(:is_manager?).and_return(false)
        expect(subject).to receive(:is_viewer?).and_return(false)
        expect(subject).to receive(:permitted_apos).and_return([1])
        expect(subject.can_view_something?).to be true
      end
    end
  end

  # TODO
  describe 'permitted_apos' do
    it 'not implemented'
  end
  describe 'permitted_collections' do
    it 'not implemented'
  end
end
