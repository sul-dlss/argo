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

  describe 'is_admin' do
    it 'is aliased to is_admin?' do
      allow(subject).to receive(:groups).and_return(User::ADMIN_GROUPS)
      expect(subject).to respond_to('is_admin?')
      expect(subject.is_admin).to be true
      expect(subject.is_admin?).to be true
      expect(subject.is_admin).to be subject.is_admin?
    end
    it 'should be true if the group is an admin group' do
      allow(subject).to receive(:groups).and_return(['workgroup:sdr:administrator-role'])
      expect(subject.is_admin).to be true
    end
    it 'should be false if the group is a deprecated admin group' do
      allow(subject).to receive(:groups).and_return(['workgroup:dlss:dor-admin'])
      expect(subject.is_admin).to be false
    end
    it 'should be false for a blank group' do
      allow(subject).to receive(:groups).and_return([])
      expect(subject.is_admin).to be false
      allow(subject).to receive(:groups).and_return(nil)
      expect(subject.is_admin).to be false
    end
    it 'should be false with an inadequate group membership' do
      allow(subject).to receive(:groups).and_return(['workgroup:dlss:not-admin'])
      expect(subject.is_admin).to be false
    end
    it 'should be true for ADMIN_GROUPS' do
      allow(subject).to receive(:groups).and_return(User::ADMIN_GROUPS)
      expect(subject.is_admin).to be true
    end
    it 'should be false for MANAGER_GROUPS' do
      allow(subject).to receive(:groups).and_return(User::MANAGER_GROUPS)
      expect(subject.is_admin).to be false
    end
    it 'should be false for VIEWER_GROUPS' do
      allow(subject).to receive(:groups).and_return(User::VIEWER_GROUPS)
      expect(subject.is_admin).to be false
    end
  end

  describe 'is_manager' do
    it 'is aliased to is_manager?' do
      allow(subject).to receive(:groups).and_return(User::MANAGER_GROUPS)
      expect(subject).to respond_to('is_manager?')
      expect(subject.is_manager).to be true
      expect(subject.is_manager?).to be true
      expect(subject.is_manager).to be subject.is_manager?
    end
    it 'should be true if the group is a manager group' do
      allow(subject).to receive(:groups).and_return(['workgroup:sdr:manager-role'])
      expect(subject.is_manager).to be true
    end
    it 'should be false if the group is a deprecated manager group' do
      allow(subject).to receive(:groups).and_return(['workgroup:dlss:dor-manager'])
      expect(subject.is_manager).to be false
    end
    it 'should be false for a blank group' do
      allow(subject).to receive(:groups).and_return([])
      expect(subject.is_manager).to be false
      allow(subject).to receive(:groups).and_return(nil)
      expect(subject.is_manager).to be false
    end
    it 'should be false with an inadequate group membership' do
      allow(subject).to receive(:groups).and_return(['workgroup:dlss:not-manager'])
      expect(subject.is_manager).to be false
    end
    it 'should be false for ADMIN_GROUPS' do
      allow(subject).to receive(:groups).and_return(User::ADMIN_GROUPS)
      expect(subject.is_manager).to be false
    end
    it 'should be true for MANAGER_GROUPS' do
      allow(subject).to receive(:groups).and_return(User::MANAGER_GROUPS)
      expect(subject.is_manager).to be true
    end
    it 'should be false for VIEWER_GROUPS' do
      allow(subject).to receive(:groups).and_return(User::VIEWER_GROUPS)
      expect(subject.is_manager).to be false
    end
  end

  describe 'is_viewer' do
    it 'is aliased to is_viewer?' do
      allow(subject).to receive(:groups).and_return(User::VIEWER_GROUPS)
      expect(subject).to respond_to('is_viewer?')
      expect(subject.is_viewer).to be true
      expect(subject.is_viewer?).to be true
      expect(subject.is_viewer).to be subject.is_viewer?
    end
    it 'should be true if the group is a viewer group' do
      allow(subject).to receive(:groups).and_return(['workgroup:sdr:viewer-role'])
      expect(subject.is_viewer).to be true
    end
    it 'should be false if the group is a deprecated viewer group' do
      allow(subject).to receive(:groups).and_return(['workgroup:dlss:dor-viewer'])
      expect(subject.is_viewer).to be false
    end
    it 'should be false for a blank group' do
      allow(subject).to receive(:groups).and_return([])
      expect(subject.is_viewer).to be false
      allow(subject).to receive(:groups).and_return(nil)
      expect(subject.is_viewer).to be false
    end
    it 'should be false with an inadequate group membership' do
      allow(subject).to receive(:groups).and_return(['workgroup:dlss:not-viewer'])
      expect(subject.is_viewer).to be false
    end
    it 'should be false for ADMIN_GROUPS' do
      allow(subject).to receive(:groups).and_return(User::ADMIN_GROUPS)
      expect(subject.is_viewer).to be false
    end
    it 'should be false for MANAGER_GROUPS' do
      allow(subject).to receive(:groups).and_return(User::MANAGER_GROUPS)
      expect(subject.is_viewer).to be false
    end
    it 'should be true for VIEWER_GROUPS' do
      allow(subject).to receive(:groups).and_return(User::VIEWER_GROUPS)
      expect(subject.is_viewer).to be true
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
      expect(user.is_admin).to be true
      expect(user.is_manager).to be true
      expect(user.is_viewer).to be true
      user.set_groups_to_impersonate(%w(workgroup:sdr:not-an-administrator-role workgroup:sdr:not-a-manager-role workgroup:sdr:not-a-viewer-role))
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

  describe '#can_admin?' do
    before :each do
      expect(subject).not_to receive(:is_manager)
      expect(subject).not_to receive(:is_viewer)
    end

    shared_examples 'Argo grants permission to manage object' do
      it 'permits admin' do
        expect(subject).to receive(:is_admin).once.and_return(true)
        expect(subject).not_to receive(:is_manager)
        expect(subject).not_to receive(:is_viewer)
        expect(subject.can_admin?(item)).to be true
      end
      it 'denies manager' do
        expect(subject).to receive(:is_admin).once.and_return(false)
        expect(subject).not_to receive(:is_manager)
        expect(subject).not_to receive(:is_viewer)
        expect(subject.can_admin?(item)).to be false
      end
    end

    context 'checks object permissions' do
      let(:druid) { 'druid:hv992ry2431' }
      let(:item) { instantiate_fixture(druid, Dor::AdminPolicyObject) }
      context 'when user has no Argo permissions' do
        before :each do
          expect(subject).to receive(:is_admin).once.and_return(false)
        end
        it 'using default "can_manage_item?"' do
          expect(item).to receive(:can_manage_item?).at_least(:once)
          subject.can_admin?(item)
        end
        it 'using custom "can_manage_content?"' do
          expect(item).to receive(:can_manage_content?).at_least(:once)
          subject.can_admin?(item, 'content')
        end
        it 'raises ArgumentError for invalid permissions' do
          expect{subject.can_admin?(item, 'WTF')}.to raise_error(ArgumentError)
        end
      end
    end

    context 'DOR object is an APO with a governing APO' do
      let(:druid) { 'druid:hv992ry2431' }
      let(:item) { instantiate_fixture(druid, Dor::AdminPolicyObject) }
      let(:apo) { item.admin_policy_object }
      it_behaves_like 'Argo grants permission to manage object'
      context 'when user has no Argo permissions' do
        before :each do
          expect(subject).to receive(:is_admin).once.and_return(false)
        end
        it 'allows user with authorized role in governing APO' do
          # This checks the governing APO and grants permission.
          role = 'sdr-administrator'
          expect(subject).to receive(:roles).with(apo.pid).once.and_return([role])
          expect(subject).not_to receive(:roles).with(item.pid)
          expect(item).to receive(:can_manage_item?).with([role]).once.and_return(true)
          expect(subject.can_admin?(item)).to be true
        end
        it 'allows user with authorized role in item APO' do
          # This checks the governing APO and does not grant permission;
          # it then checks the item APO and grants permission.
          apo_role = 'not-administrator'
          item_role = 'sdr-administrator'
          expect(subject).to receive(:roles).with(apo.pid).once.and_return([apo_role])
          expect(subject).to receive(:roles).with(item.pid).once.and_return([item_role])
          expect(item).to receive(:can_manage_item?).with([apo_role]).once.and_return(false)
          expect(item).to receive(:can_manage_item?).with([item_role]).once.and_return(true)
          expect(subject.can_admin?(item)).to be true
        end
        it 'forbids user without authorized role in any APO' do
          # This checks the governing APO and does not grant permission;
          # it then checks the item APO and does not grant permission.
          role = 'sdr-viewer'
          expect(subject).to receive(:roles).with(apo.pid).once.and_return([role])
          expect(subject).to receive(:roles).with(item.pid).once.and_return([role])
          expect(item).to receive(:can_manage_item?).with([role]).twice.and_return(false)
          expect(subject.can_admin?(item)).to be false
        end
      end
    end

    context 'DOR object is an APO without a governing APO' do
      let(:druid) { 'druid:hv992ry2431' }
      let(:item) do
        item = instantiate_fixture(druid, Dor::AdminPolicyObject)
        allow(item).to receive(:admin_policy_object).and_return(nil)
        item
      end
      it_behaves_like 'Argo grants permission to manage object'
      context 'when user has no Argo permissions' do
        before :each do
          expect(subject).to receive(:is_admin).once.and_return(false)
        end
        it 'allows user with authorized role' do
          # There is no governing APO to grant permission, so
          # it checks the item APO and grants permission.
          role = 'sdr-administrator'
          expect(subject).to receive(:roles).with(item.pid).once.and_return([role])
          expect(item).to receive(:can_manage_item?).with([role]).once.and_return(true)
          expect(subject.can_admin?(item)).to be true
        end
        it 'forbids user without authorized role' do
          # There is no governing APO to grant permission, so
          # it checks the item APO and does not grant permission.
          role = 'sdr-viewer'
          expect(subject).to receive(:roles).with(item.pid).once.and_return([role])
          expect(item).to receive(:can_manage_item?).with([role]).once.and_return(false)
          expect(subject.can_admin?(item)).to be false
        end
      end
    end
  end

  describe '#can_manage?' do
    before :each do
      expect(subject).not_to receive(:is_viewer)
    end

    shared_examples 'Argo grants permission to manage object' do
      it 'permits admin' do
        expect(subject).to receive(:is_admin).once.and_return(true)
        expect(subject).not_to receive(:is_manager)
        expect(subject).not_to receive(:is_viewer)
        expect(subject.can_manage?(item)).to be true
      end
      it 'permits manager' do
        expect(subject).to receive(:is_admin).once.and_return(false)
        expect(subject).to receive(:is_manager).once.and_return(true)
        expect(subject).not_to receive(:is_viewer)
        expect(subject.can_manage?(item)).to be true
      end
    end

    context 'checks object permissions' do
      let(:druid) { 'druid:hv992ry2431' }
      let(:item) { instantiate_fixture(druid, Dor::AdminPolicyObject) }
      context 'when user has no Argo permissions' do
        before :each do
          expect(subject).to receive(:is_admin).once.and_return(false)
          expect(subject).to receive(:is_manager).once.and_return(false)
        end
        it 'using default "can_manage_item?"' do
          expect(item).to receive(:can_manage_item?).at_least(:once)
          subject.can_manage?(item)
        end
        it 'using custom "can_manage_content?"' do
          expect(item).to receive(:can_manage_content?).at_least(:once)
          subject.can_manage?(item, 'content')
        end
        it 'raises ArgumentError for invalid permissions' do
          expect{subject.can_manage?(item, 'WTF')}.to raise_error(ArgumentError)
        end
      end
    end

    context 'DOR object is an APO with a governing APO' do
      let(:druid) { 'druid:hv992ry2431' }
      let(:item) { instantiate_fixture(druid, Dor::AdminPolicyObject) }
      let(:apo) { item.admin_policy_object }
      it_behaves_like 'Argo grants permission to manage object'
      context 'when user has no Argo permissions' do
        before :each do
          expect(subject).to receive(:is_admin).once.and_return(false)
          expect(subject).to receive(:is_manager).once.and_return(false)
        end
        it 'allows user with authorized role in governing APO' do
          # This checks the governing APO and grants permission.
          role = 'sdr-administrator'
          expect(subject).to receive(:roles).with(apo.pid).once.and_return([role])
          expect(subject).not_to receive(:roles).with(item.pid)
          expect(item).to receive(:can_manage_item?).with([role]).once.and_return(true)
          expect(subject.can_manage?(item)).to be true
        end
        it 'allows user with authorized role in item APO' do
          # This checks the governing APO and does not grant permission;
          # it then checks the item APO and grants permission.
          apo_role = 'not-administrator'
          item_role = 'sdr-administrator'
          expect(subject).to receive(:roles).with(apo.pid).once.and_return([apo_role])
          expect(subject).to receive(:roles).with(item.pid).once.and_return([item_role])
          expect(item).to receive(:can_manage_item?).with([apo_role]).once.and_return(false)
          expect(item).to receive(:can_manage_item?).with([item_role]).once.and_return(true)
          expect(subject.can_manage?(item)).to be true
        end
        it 'forbids user without authorized role in any APO' do
          # This checks the governing APO and does not grant permission;
          # it then checks the item APO and does not grant permission.
          role = 'sdr-viewer'
          expect(subject).to receive(:roles).with(apo.pid).once.and_return([role])
          expect(subject).to receive(:roles).with(item.pid).once.and_return([role])
          expect(item).to receive(:can_manage_item?).with([role]).twice.and_return(false)
          expect(subject.can_manage?(item)).to be false
        end
      end
    end

    context 'DOR object is an APO without a governing APO' do
      let(:druid) { 'druid:hv992ry2431' }
      let(:item) do
        item = instantiate_fixture(druid, Dor::AdminPolicyObject)
        allow(item).to receive(:admin_policy_object).and_return(nil)
        item
      end
      it_behaves_like 'Argo grants permission to manage object'
      context 'when user has no Argo permissions' do
        before :each do
          expect(subject).to receive(:is_admin).once.and_return(false)
          expect(subject).to receive(:is_manager).once.and_return(false)
        end
        it 'allows user with authorized role' do
          # There is no governing APO to grant permission, so
          # it checks the item APO and grants permission.
          role = 'sdr-administrator'
          expect(subject).to receive(:roles).with(item.pid).once.and_return([role])
          expect(item).to receive(:can_manage_item?).with([role]).once.and_return(true)
          expect(subject.can_manage?(item)).to be true
        end
        it 'forbids user without authorized role' do
          # There is no governing APO to grant permission, so
          # it checks the item APO and does not grant permission.
          role = 'sdr-viewer'
          expect(subject).to receive(:roles).with(item.pid).once.and_return([role])
          expect(item).to receive(:can_manage_item?).with([role]).once.and_return(false)
          expect(subject.can_manage?(item)).to be false
        end
      end
    end
  end

  describe '#can_view?' do
    shared_examples 'Argo grants permission to view object' do
      it 'permits admin' do
        expect(subject).to receive(:is_admin).once.and_return(true)
        expect(subject).not_to receive(:is_manager)
        expect(subject).not_to receive(:is_viewer)
        expect(subject.can_view?(item)).to be true
      end
      it 'permits manager' do
        expect(subject).to receive(:is_admin).once.and_return(false)
        expect(subject).to receive(:is_manager).once.and_return(true)
        expect(subject).not_to receive(:is_viewer)
        expect(subject.can_view?(item)).to be true
      end
      it 'permits viewer' do
        expect(subject).to receive(:is_admin).once.and_return(false)
        expect(subject).to receive(:is_manager).once.and_return(false)
        expect(subject).to receive(:is_viewer).once.and_return(true)
        expect(subject.can_view?(item)).to be true
      end
    end

    context 'checks object permissions' do
      let(:druid) { 'druid:hv992ry2431' }
      let(:item) { instantiate_fixture(druid, Dor::AdminPolicyObject) }
      context 'when user has no Argo permissions' do
        before :each do
          expect(subject).to receive(:is_admin).once.and_return(false)
          expect(subject).to receive(:is_manager).once.and_return(false)
          expect(subject).to receive(:is_viewer).once.and_return(false)
        end
        it 'using default "can_view_metadata?"' do
          expect(item).to receive(:can_view_metadata?).at_least(:once)
          subject.can_view?(item)
        end
        it 'using custom "can_view_content?"' do
          expect(item).to receive(:can_view_content?).at_least(:once)
          subject.can_view?(item, 'content')
        end
        it 'raises ArgumentError for invalid permissions' do
          expect{subject.can_view?(item, 'WTF')}.to raise_error(ArgumentError)
        end
      end
    end

    context 'DOR object is an APO with a governing APO' do
      let(:druid) { 'druid:hv992ry2431' }
      let(:item) { instantiate_fixture(druid, Dor::AdminPolicyObject) }
      let(:apo) { item.admin_policy_object }
      it_behaves_like 'Argo grants permission to view object'
      context 'when user has no Argo permissions' do
        before :each do
          expect(subject).to receive(:is_admin).once.and_return(false)
          expect(subject).to receive(:is_manager).once.and_return(false)
          expect(subject).to receive(:is_viewer).once.and_return(false)
        end
        it 'allows user with authorized role in governing APO' do
          # This checks the governing APO and grants permission.
          role = 'sdr-viewer'
          expect(subject).to receive(:roles).with(apo.pid).once.and_return([role])
          expect(subject).not_to receive(:roles).with(item.pid)
          expect(item).to receive(:can_view_metadata?).with([role]).once.and_return(true)
          expect(subject.can_view?(item)).to be true
        end
        it 'allows user with authorized role in item APO' do
          # This checks the governing APO and does not grant permission;
          # it then checks the item APO and grants permission.
          apo_role = 'not-administrator'
          item_role = 'sdr-administrator'
          expect(subject).to receive(:roles).with(apo.pid).once.and_return([apo_role])
          expect(subject).to receive(:roles).with(item.pid).once.and_return([item_role])
          expect(item).to receive(:can_view_metadata?).with([apo_role]).once.and_return(false)
          expect(item).to receive(:can_view_metadata?).with([item_role]).once.and_return(true)
          expect(subject.can_view?(item)).to be true
        end
        it 'forbids user without authorized role in any APO' do
          # This checks the governing APO and does not grant permission;
          # it then checks the item APO and does not grant permission.
          role = 'sdr-viewer'
          expect(subject).to receive(:roles).with(apo.pid).once.and_return([role])
          expect(subject).to receive(:roles).with(item.pid).once.and_return([role])
          expect(item).to receive(:can_view_metadata?).with([role]).twice.and_return(false)
          expect(subject.can_view?(item)).to be false
        end
      end
    end

    context 'DOR object is an APO without a governing APO' do
      let(:druid) { 'druid:hv992ry2431' }
      let(:item) do
        item = instantiate_fixture(druid, Dor::AdminPolicyObject)
        allow(item).to receive(:admin_policy_object).and_return(nil)
        item
      end
      it_behaves_like 'Argo grants permission to view object'
      context 'when user has no Argo permissions' do
        before :each do
          expect(subject).to receive(:is_admin).once.and_return(false)
          expect(subject).to receive(:is_manager).once.and_return(false)
          expect(subject).to receive(:is_viewer).once.and_return(false)
        end
        it 'allows user with authorized role' do
          # There is no governing APO to grant permission, so
          # it checks the item APO and grants permission.
          role = 'sdr-administrator'
          expect(subject).to receive(:roles).with(item.pid).once.and_return([role])
          expect(item).to receive(:can_view_metadata?).with([role]).once.and_return(true)
          expect(subject.can_view?(item)).to be true
        end
        it 'forbids user without authorized role' do
          # There is no governing APO to grant permission, so
          # it checks the item APO and does not grant permission.
          role = 'sdr-viewer'
          expect(subject).to receive(:roles).with(item.pid).once.and_return([role])
          expect(item).to receive(:can_view_metadata?).with([role]).once.and_return(false)
          expect(subject.can_view?(item)).to be false
        end
      end
    end
  end

  describe '#get_dor_object' do
    # These specs call `subject.send(:get_dor_object)` because it is private.
    let(:druid) { 'mt603cr6214' }
    it 'returns a DOR object, as is' do
      item = instantiate_fixture(druid)
      expect(Dor).not_to receive(:find)
      obj = subject.send(:get_dor_object, item)
      expect(obj.pid).to eq(item.pid)
    end
    it 'uses Dor.find to get a DOR object' do
      expect(Dor).to receive(:find).with(druid)
      subject.send(:get_dor_object, druid)
    end
    it 'a PID that does not exist will raise ActiveFedora::ObjectNotFoundError' do
      expect(Dor).to receive(:find).and_call_original
      expect{subject.send(:get_dor_object, 'druid:aa111aa1111')}.to raise_error(ActiveFedora::ObjectNotFoundError)
    end
    it 'a PID without a "druid:" prefix will raise Rubydora::FedoraInvalidRequest' do
      skip('This only occurs on my laptop [D.L. Weber]')
      expect(Dor).to receive(:find).and_call_original
      expect{subject.send(:get_dor_object, 'aa111aa1111')}.to raise_error(Rubydora::FedoraInvalidRequest)
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
