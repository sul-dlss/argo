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
    def expect_admin(value)
      expect(subject.is_admin).to be value
      expect(subject.is_admin?).to be value
    end
    it 'should be true if the group is an admin group' do
      allow(subject).to receive(:groups).and_return(['workgroup:sdr:administrator-role'])
      expect_admin true
    end
    it 'should be true if the group is a deprecated admin group' do
      allow(subject).to receive(:groups).and_return(['workgroup:dlss:dor-admin'])
      expect_admin true
    end
    it 'should be false for a blank group' do
      allow(subject).to receive(:groups).and_return([])
      expect_admin false
      allow(subject).to receive(:groups).and_return(nil)
      expect_admin false
    end
    it 'should be false with an inadequate group membership' do
      allow(subject).to receive(:groups).and_return(['workgroup:dlss:not-admin'])
      expect_admin false
    end
    it 'should be true for ADMIN_GROUPS' do
      allow(subject).to receive(:groups).and_return(User::ADMIN_GROUPS)
      expect_admin true
    end
    it 'should be false for MANAGER_GROUPS' do
      allow(subject).to receive(:groups).and_return(User::MANAGER_GROUPS)
      expect_admin false
    end
    it 'should be false for VIEWER_GROUPS' do
      allow(subject).to receive(:groups).and_return(User::VIEWER_GROUPS)
      expect_admin false
    end
  end

  describe 'is_manager' do
    def expect_manager(value)
      expect(subject.is_manager).to be value
      expect(subject.is_manager?).to be value
    end
    it 'should be true if the group is a manager group' do
      allow(subject).to receive(:groups).and_return(['workgroup:sdr:manager-role'])
      expect_manager true
    end
    it 'should be true if the group is a deprecated manager group' do
      allow(subject).to receive(:groups).and_return(['workgroup:dlss:dor-manager'])
      expect_manager true
    end
    it 'should be false for a blank group' do
      allow(subject).to receive(:groups).and_return([])
      expect_manager false
      allow(subject).to receive(:groups).and_return(nil)
      expect_manager false
    end
    it 'should be false with an inadequate group membership' do
      allow(subject).to receive(:groups).and_return(['workgroup:dlss:not-manager'])
      expect_manager false
    end
    it 'should be false for ADMIN_GROUPS' do
      allow(subject).to receive(:groups).and_return(User::ADMIN_GROUPS)
      expect_manager false
    end
    it 'should be true for MANAGER_GROUPS' do
      allow(subject).to receive(:groups).and_return(User::MANAGER_GROUPS)
      expect_manager true
    end
    it 'should be false for VIEWER_GROUPS' do
      allow(subject).to receive(:groups).and_return(User::VIEWER_GROUPS)
      expect_manager false
    end
  end

  describe 'is_viewer' do
    def expect_viewer(value)
      expect(subject.is_viewer).to be value
      expect(subject.is_viewer?).to be value
    end
    it 'should be true if the group is a viewer group' do
      allow(subject).to receive(:groups).and_return(['workgroup:sdr:viewer-role'])
      expect_viewer true
    end
    it 'should be true if the group is a deprecated viewer group' do
      allow(subject).to receive(:groups).and_return(['workgroup:dlss:dor-viewer'])
      expect_viewer true
    end
    it 'should be false for a blank group' do
      allow(subject).to receive(:groups).and_return([])
      expect_viewer false
      allow(subject).to receive(:groups).and_return(nil)
      expect_viewer false
    end
    it 'should be false for ADMIN_GROUPS' do
      allow(subject).to receive(:groups).and_return(User::ADMIN_GROUPS)
      expect_viewer false
    end
    it 'should be false for MANAGER_GROUPS' do
      allow(subject).to receive(:groups).and_return(User::MANAGER_GROUPS)
      expect_viewer false
    end
    it 'should be true for VIEWER_GROUPS' do
      allow(subject).to receive(:groups).and_return(User::VIEWER_GROUPS)
      expect_viewer true
    end
  end

  describe 'role_allowed' do
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
      expect(subject.role_allowed?(solr_doc, 'roleA')).to be true
    end
    it 'returns false when DOR solr document has a role with values that do not include a user group' do
      allow(subject).to receive(:groups).and_return(['dlss:groupX'])
      expect(subject.role_allowed?(solr_doc, 'roleA')).to be false
    end
    it 'returns false when DOR solr document has no matching roles' do
      expect(subject.role_allowed?(solr_doc, 'roleX')).to be false
    end
    it 'returns false when DOR solr document is empty' do
      expect(subject.role_allowed?({}, 'roleA')).to be false
    end
    it 'returns false when user belongs to no groups' do
      allow(subject).to receive(:groups).and_return([])
      expect(subject.role_allowed?(solr_doc, 'roleA')).to be false
    end
  end

  describe 'roles' do
    # The exact DRUID is not important in these specs, because
    # the Dor::SearchService is mocked to return solr_doc.
    let(:druid) { 'ab123cd4567' }
    let(:pid) { DruidTools::Druid.new(druid).druid }
    let(:answer) do
      {
        'response' => { 'docs' => [solr_doc] }
      }
    end
    let(:solr_doc) do
      {
        'apo_role_dor-administrator_ssim' => ['workgroup:dlss:groupA', 'workgroup:dlss:groupB'],
        'apo_role_sdr-administrator_ssim' => ['workgroup:dlss:groupA', 'workgroup:dlss:groupB'],
        'apo_role_dor-apo-manager_ssim'   => ['workgroup:dlss:groupC', 'workgroup:dlss:groupD'],
        'apo_role_dor-viewer_ssim'        => ['workgroup:dlss:groupE', 'workgroup:dlss:groupF'],
        'apo_role_sdr-viewer_ssim'        => ['workgroup:dlss:groupE', 'workgroup:dlss:groupF'],
        'apo_role_person_dor-viewer_ssim' => ['sunetid:tcramer'],
        'apo_role_person_sdr-viewer_ssim' => ['sunetid:tcramer'],
        'apo_role_group_manager_ssim'     => ['workgroup:dlss:groupR']
      }
    end
    before(:each) do
      allow(Dor::SearchService).to receive(:query).and_return(answer)
    end
    it 'should accept any valid DRUID' do
      expect{subject.roles(druid)}.not_to raise_error
      expect{subject.roles(pid)}.not_to raise_error
    end
    it 'should raise ArgumentError for an invalid DRUID' do
      expect{subject.roles('invalid_druid')}.to raise_error ArgumentError
    end
    it 'should build a set of roles from groups' do
      doc_groups = ['workgroup:dlss:groupF', 'workgroup:dlss:groupA']
      doc_roles = ['dor-administrator', 'sdr-administrator', 'dor-viewer', 'sdr-viewer'].sort
      expect(subject).to receive(:groups).and_return(doc_groups).at_least(:once)
      expect(subject.roles(druid)).to eq(doc_roles)
    end
    it 'should translate the old "manager" role into dor-apo-manager' do
      expect(subject).to receive(:groups).and_return(['workgroup:dlss:groupR']).at_least(:once)
      expect(subject.roles(druid)).to eq(['dor-apo-manager'])
    end
    it 'should return an empty set of roles if the DRUID solr search fails' do
      empty_doc = { 'response' => { 'docs' => [] } }
      allow(Dor::SearchService).to receive(:query).and_return(empty_doc)
      expect(subject).not_to receive(:groups) # short circuit for empty solr doc
      expect(subject.roles(druid)).to be_empty
    end
    it 'should work correctly if the individual is named in the apo, but is not in any groups that matter' do
      expect(subject).to receive(:groups).and_return(['sunetid:tcramer']).at_least(:once)
      expect(subject.roles(druid)).to eq(['dor-viewer', 'sdr-viewer'])
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
        impersonated_groups = ['workgroup:dlss:impersonatedgroup1', 'workgroup:dlss:impersonatedgroup2']
        @user.set_groups_to_impersonate(impersonated_groups)
        expect(@user.groups).to eq(impersonated_groups)
      end
    end
    it "should return false for is_admin/is_manager/is_viewer if such groups aren't specified for impersonation, even if the user is part of the admin/manager/viewer groups" do
      webauth_privgroup_str = 'sdr:administrator-role|sdr:manager-role|sdr:viewer-role'
      mock_webauth = double('webauth', :login => 'asdf', :logged_in? => true, :privgroup => webauth_privgroup_str)
      user = User.find_or_create_by_webauth(mock_webauth)
      expect(user.is_admin).to be true
      expect(user.is_manager).to be true
      expect(user.is_viewer).to be true
      user.set_groups_to_impersonate(['workgroup:sdr:not-an-administrator-role', 'workgroup:sdr:not-a-manager-role', 'workgroup:sdr:not-a-viewer-role'])
      expect(user.is_admin).to be false
      expect(user.is_manager).to be false
      expect(user.is_viewer).to be false
    end
  end

  describe 'set_groups_to_impersonate' do
    def groups_to_impersonate
      subject.instance_variable_get(:@groups_to_impersonate)
    end
    before :each do
      subject.instance_variable_set(:@groups_to_impersonate, ['a', 'b'])
    end
    it 'resets the role_cache' do
      subject.instance_variable_set(:@role_cache, {a: 1})
      subject.set_groups_to_impersonate []
      expect(subject.instance_variable_get(:@role_cache)).to be_empty
    end
    it 'removes impersonation groups when given nil' do
      subject.set_groups_to_impersonate nil
      expect(groups_to_impersonate).to be_blank
    end
    it 'removes impersonation groups when given an empty String' do
      subject.set_groups_to_impersonate ''
      expect(groups_to_impersonate).to be_blank
    end
    it 'removes impersonation groups when given an empty Array' do
      subject.set_groups_to_impersonate []
      expect(groups_to_impersonate).to be_blank
    end
    it 'removes impersonation groups when given an empty Hash' do
      subject.set_groups_to_impersonate({})
      expect(groups_to_impersonate).to be_blank
    end
    it 'accepts a String argument' do
      subject.set_groups_to_impersonate 'groupA'
      expect(groups_to_impersonate).to eq ['groupA']
    end
    it 'accepts an Array<String> argument' do
      subject.set_groups_to_impersonate ['groupA']
      expect(groups_to_impersonate).to eq ['groupA']
    end
    it 'raises ArgumentError for other arguments' do
      expect{subject.set_groups_to_impersonate({a: 1})}.to raise_error ArgumentError
      expect{subject.set_groups_to_impersonate(0)}.to raise_error ArgumentError
    end
  end

  describe '#can_view_something?' do
    it 'returns false' do
      expect(subject.can_view_something?).to be false
    end
    context 'when admin' do
      it 'returns true' do
        expect(subject).to receive(:is_admin).and_return(true)
        expect(subject.can_view_something?).to be true
      end
    end
    context 'when manager' do
      it 'returns true' do
        expect(subject).to receive(:is_admin).and_return(false)
        expect(subject).to receive(:is_manager).and_return(true)
        expect(subject.can_view_something?).to be true
      end
    end
    context 'when viewer' do
      it 'returns true' do
        expect(subject).to receive(:is_admin).and_return(false)
        expect(subject).to receive(:is_manager).and_return(false)
        expect(subject).to receive(:is_viewer).and_return(true)
        expect(subject.can_view_something?).to be true
      end
    end
    context 'with permitted_apos' do
      it 'returns true' do
        expect(subject).to receive(:is_admin).and_return(false)
        expect(subject).to receive(:is_manager).and_return(false)
        expect(subject).to receive(:is_viewer).and_return(false)
        expect(subject).to receive(:permitted_apos).and_return([1])
        expect(subject.can_view_something?).to be true
      end
    end
  end

  describe '#can_manage_object?' do
    let(:druid) { 'druid:hv992ry2431' }
    let(:item) { instantiate_fixture(druid, Dor::AdminPolicyObject) }
    before :each do
      expect(subject).not_to receive(:is_viewer)
    end
    it 'returns false' do
      expect(subject.can_manage_object?(item)).to be false
    end
    context 'when admin' do
      it 'returns true' do
        expect(subject).to receive(:is_admin).and_return(true)
        expect(subject).not_to receive(:is_manager)
        expect(subject.can_manage_object?(item)).to be true
      end
    end
    context 'when manager' do
      it 'returns true' do
        expect(subject).to receive(:is_admin).and_return(false)
        expect(subject).to receive(:is_manager).and_return(true)
        expect(subject.can_manage_object?(item)).to be true
      end
    end
    context 'when viewer' do
      it 'returns false' do
        expect(subject).to receive(:is_admin).and_return(false)
        expect(subject).to receive(:is_manager).and_return(false)
        allow(item).to receive(:can_manage_item?).and_return(false)
        allow(item).to receive(:can_manage_content?).and_return(false)
        expect(subject.can_manage_object?(item)).to be false
      end
    end
    context 'when user has an authorized role' do
      it 'returns true' do
        allow(subject).to receive(:is_admin).and_return(false)
        allow(subject).to receive(:is_manager).and_return(false)
        expect(item).not_to receive(:can_manage_content?)
        manager_roles = ["dor-administrator", "sdr-administrator"]
        manager_roles.each do |role|
          allow(subject).to receive(:roles).and_return([role])
          allow(item).to receive(:can_manage_item?).with([role]).and_return(true)
          # can_manage_item? supercedes can_manage_content?
          expect(subject.can_manage_object?(item)).to be true
        end
      end
    end
    context 'when user has no authorized role' do
      it 'returns false' do
        allow(subject).to receive(:is_admin).and_return(false)
        allow(subject).to receive(:is_manager).and_return(false)
        viewer_roles = ["dor-viewer", "sdr-viewer"]
        viewer_roles.each do |role|
          allow(subject).to receive(:roles).and_return([role])
          allow(item).to receive(:can_manage_item?).with([role]).and_return(false)
          allow(item).to receive(:can_manage_content?).with([role]).and_return(false)
          expect(subject.can_manage_object?(item)).to be false
        end
      end
    end
  end

  describe '#can_view_object?' do
    let(:druid) { 'druid:hv992ry2431' }
    let(:item) do
      item = instantiate_fixture(druid, Dor::AdminPolicyObject)
      # allow(Dor).to receive(:find).with(@druid).and_return(@item)
      # allow(Dor::Item).to receive(:find).with(@druid).and_return(@item)
      item
    end
    it 'returns false' do
      expect(subject.can_view_object?(item)).to be false
    end
    context 'when admin' do
      it 'returns true' do
        expect(subject).to receive(:is_admin).and_return(true)
        expect(subject).not_to receive(:is_manager)
        expect(subject).not_to receive(:is_viewer)
        expect(subject.can_view_object?(item)).to be true
      end
    end
    context 'when manager' do
      it 'returns true' do
        expect(subject).to receive(:is_admin).and_return(false)
        expect(subject).to receive(:is_manager).and_return(true)
        expect(subject).not_to receive(:is_viewer)
        expect(subject.can_view_object?(item)).to be true
      end
    end
    context 'when viewer' do
      it 'returns true' do
        expect(subject).to receive(:is_admin).and_return(false)
        expect(subject).to receive(:is_manager).and_return(false)
        expect(subject).to receive(:is_viewer).and_return(true)
        expect(subject.can_view_object?(item)).to be true
      end
    end
    context 'when user has an authorized role' do
      it 'returns true' do
        allow(subject).to receive(:is_admin).and_return(false)
        allow(subject).to receive(:is_manager).and_return(false)
        allow(subject).to receive(:is_viewer).and_return(false)
        viewer_roles = ["dor-viewer", "sdr-viewer"]
        viewer_roles.each do |role|
          allow(subject).to receive(:roles).and_return([role])
          allow(item).to receive(:can_view_content?).with([role]).and_return(true)
          expect(subject.can_view_object?(item)).to be true
        end
      end
    end
    context 'when user has no authorized role' do
      it 'returns false' do
        allow(subject).to receive(:is_admin).and_return(false)
        allow(subject).to receive(:is_manager).and_return(false)
        allow(subject).to receive(:is_viewer).and_return(false)
        role = 'unauthorized'
        allow(subject).to receive(:roles).and_return([role])
        allow(item).to receive(:can_view_content?).with([role]).and_return(false)
        expect(subject.can_view_object?(item)).to be false
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
