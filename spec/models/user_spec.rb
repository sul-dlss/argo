# frozen_string_literal: true

require 'rails_helper'

# General documentation about roles and permissions is on SUL Consul at
# https://consul.stanford.edu/display/chimera/Repository+Roles+and+Permissions

RSpec.describe User, type: :model do
  describe '#is_admin?' do
    subject { user.is_admin? }

    let(:user) { described_class.new }

    before do
      allow(user).to receive(:groups).and_return(groups)
    end

    context 'when the group is a deprecated admin group' do
      let(:groups) { ['workgroup:dlss:dor-admin'] }

      it { is_expected.to be false }
    end

    context 'when there are no groups' do
      let(:groups) { [] }

      it { is_expected.to be false }
    end

    context 'with an inadequate group membership' do
      let(:groups) { ['workgroup:dlss:not-admin'] }

      it { is_expected.to be false }
    end

    context 'with ADMIN_GROUPS' do
      let(:groups) { User::ADMIN_GROUPS }

      it { is_expected.to be true }
    end

    context 'with MANAGER_GROUPS' do
      let(:groups) { User::MANAGER_GROUPS }

      it { is_expected.to be false }
    end

    context 'with VIEWER_GROUPS' do
      let(:groups) { User::VIEWER_GROUPS }

      it { is_expected.to be false }
    end
  end

  describe '#is_webauth_admin?' do
    subject { user.is_webauth_admin? }

    let(:user) { described_class.new }

    before do
      allow(user).to receive(:webauth_groups).and_return(groups)
    end

    context 'with ADMIN_GROUPS' do
      let(:groups) { User::ADMIN_GROUPS }

      it { is_expected.to be true }
    end
  end

  describe '#is_manager?' do
    subject { user.is_manager? }

    let(:user) { described_class.new }

    before do
      allow(user).to receive(:groups).and_return(groups)
    end

    context 'when the group is a deprecated manager group' do
      let(:groups) { ['workgroup:dlss:dor-manager'] }

      it { is_expected.to be false }
    end

    context 'when there are no groups' do
      let(:groups) { [] }

      it { is_expected.to be false }
    end

    context 'with an inadequate group membership' do
      let(:groups) { ['workgroup:dlss:not-manager'] }

      it { is_expected.to be false }
    end

    context 'with ADMIN_GROUPS' do
      let(:groups) { User::ADMIN_GROUPS }

      it { is_expected.to be false }
    end

    context 'with MANAGER_GROUPS' do
      let(:groups) { User::MANAGER_GROUPS }

      it { is_expected.to be true }
    end

    context 'with VIEWER_GROUPS' do
      let(:groups) { User::VIEWER_GROUPS }

      it { is_expected.to be false }
    end
  end

  describe '#is_viewer?' do
    subject { user.is_viewer? }

    let(:user) { described_class.new }

    before do
      allow(user).to receive(:groups).and_return(groups)
    end

    context 'when the group is a deprecated viewer group' do
      let(:groups) { ['workgroup:dlss:dor-viewer'] }

      it { is_expected.to be false }
    end

    context 'when there are no groups' do
      let(:groups) { [] }

      it { is_expected.to be false }
    end

    context 'with an inadequate group membership' do
      let(:groups) { ['workgroup:dlss:not-viewer'] }

      it { is_expected.to be false }
    end

    context 'with ADMIN_GROUPS' do
      let(:groups) { User::ADMIN_GROUPS }

      it { is_expected.to be false }
    end

    context 'with MANAGER_GROUPS' do
      let(:groups) { User::MANAGER_GROUPS }

      it { is_expected.to be false }
    end

    context 'with VIEWER_GROUPS' do
      let(:groups) { User::VIEWER_GROUPS }

      it { is_expected.to be true }
    end
  end

  describe 'solr_role_allowed' do
    let(:solr_doc) do
      {
        'roleA' => ['dlss:groupA', 'dlss:groupB'],
        'roleB' => ['dlss:groupA', 'dlss:groupC']
      }
    end

    before do
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
        'apo_role_sdr-viewer_ssim' => %w(workgroup:dlss:groupE workgroup:dlss:groupF),
        'apo_role_dor-apo-manager_ssim' => %w(workgroup:dlss:groupC workgroup:dlss:groupD),
        'apo_role_person_sdr-viewer_ssim' => %w(sunetid:tcramer),
        'apo_role_group_manager_ssim' => %w(workgroup:dlss:groupR)
      }
    end

    before do
      allow(Dor::SearchService).to receive(:query).and_return(answer)
    end

    it 'accepts any object identifier' do
      expect { subject.roles(druid) }.not_to raise_error
      expect { subject.roles('anyStringOK') }.not_to raise_error
    end
    it 'returns an empty array for any blank object identifer' do
      ['', nil].each do |pid|
        expect { subject.roles(pid) }.not_to raise_error
        expect(subject.roles(pid)).to be_empty
      end
    end
    it 'builds a set of roles from groups' do
      user_groups = %w(workgroup:dlss:groupF workgroup:dlss:groupA)
      user_roles = %w(sdr-administrator sdr-viewer)
      expect(subject).to receive(:groups).and_return(user_groups).at_least(:once)
      expect(subject.roles(druid)).to eq(user_roles)
    end
    it 'translates the old "manager" role into dor-apo-manager' do
      expect(subject).to receive(:groups).and_return(['workgroup:dlss:groupR']).at_least(:once)
      expect(subject.roles(druid)).to eq(['dor-apo-manager'])
    end
    it 'returns an empty set of roles if the DRUID solr search fails' do
      empty_doc = { 'response' => { 'docs' => [] } }
      allow(Dor::SearchService).to receive(:query).and_return(empty_doc)
      # check that the code will return immediately if solr doc is empty
      expect(subject).not_to receive(:groups)
      expect(subject).not_to receive(:solr_role_allowed?)
      expect(subject.roles(druid)).to be_empty
    end
    it 'works correctly if the individual is named in the apo, but is not in any groups that matter' do
      expect(subject).to receive(:groups).and_return(['sunetid:tcramer']).at_least(:once)
      expect(subject.roles(druid)).to eq(['sdr-viewer'])
    end
    it 'hangs onto results through the life of the user object, avoiding multiple solr searches to find the roles for the same pid multiple times' do
      expect(subject).to receive(:groups).and_return(['testdoesnotcarewhatishere']).at_least(:once)
      expect(Dor::SearchService).to receive(:query).once
      subject.roles(druid)
      subject.roles(druid)
    end
  end

  describe '#groups' do
    subject { user.groups }

    let(:user) { build(:user, sunetid: 'asdf', webauth_groups: webauth_groups) }

    context 'specified' do
      let(:webauth_groups) { %w(dlss:testgroup1 dlss:testgroup2 dlss:testgroup3) }

      it 'returns the groups by webauth' do
        expected_groups = ['sunetid:asdf'] + webauth_groups.map { |g| "workgroup:#{g}" }
        expect(subject).to eq(expected_groups)
      end
    end

    context 'when impersonating' do
      before do
        user.set_groups_to_impersonate(%w(workgroup:dlss:impersonatedgroup1 workgroup:dlss:impersonatedgroup2))
      end

      context 'and the impersonating user is an admin' do
        let(:webauth_groups) { User::ADMIN_GROUPS }

        it 'returns only the impersonated groups' do
          expect(subject).not_to include User::ADMIN_GROUPS
        end
      end

      context 'and the impersonating user is an manager' do
        let(:webauth_groups) { User::MANAGER_GROUPS }

        it 'returns only the impersonated groups' do
          expect(subject).not_to include User::MANAGER_GROUPS
        end
      end

      context 'and the impersonating user is a viewer' do
        let(:webauth_groups) { User::VIEWER_GROUPS }

        it 'returns only the impersonated groups' do
          expect(subject).not_to include User::VIEWER_GROUPS
        end
      end
    end
  end

  describe '#webauth_groups' do
    subject { user.webauth_groups }

    let(:user) { build(:user, sunetid: 'asdf') }

    it { is_expected.to eq ['sunetid:asdf'] }

    context 'when webauth groups have been set' do
      before do
        user.webauth_groups = webauth_groups
      end

      let(:webauth_groups) { %w(dlss:testgroup1 dlss:testgroup2 dlss:testgroup3) }

      it 'returns the groups by webauth' do
        expected_groups = ['sunetid:asdf'] + webauth_groups.map { |g| "workgroup:#{g}" }
        expect(subject).to eq(expected_groups)
      end
    end
  end

  describe 'set_groups_to_impersonate' do
    def groups_to_impersonate
      subject.instance_variable_get(:@groups_to_impersonate)
    end
    before do
      subject.instance_variable_set(:@groups_to_impersonate, %w(a b))
    end

    it 'resets the role_cache' do
      subject.instance_variable_set(:@role_cache, a: 1)
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
end
