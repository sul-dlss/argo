# frozen_string_literal: true

require 'rails_helper'

# General documentation about roles and permissions is on SUL Consul at
# https://consul.stanford.edu/display/chimera/Repository+Roles+and+Permissions

RSpec.describe User do
  let(:admin_policy) do
    Cocina::Models::AdminPolicy.new(
      administrative: {
        accessTemplate: {
          view: 'world',
          controlledDigitalLending: false,
          download: 'world',
          location: nil,
          copyright: 'My copyright statement',
          license: 'https://creativecommons.org/licenses/by-nc/3.0/legalcode',
          useAndReproductionStatement: 'My use and reproduction statement'
        },
        hasAdminPolicy: 'druid:xx666zz7777',
        hasAgreement: 'druid:dd327rv8888',
        roles:
      },
      description: {
        title: [{ value: 'My title' }],
        purl: 'https://purl.stanford.edu/zt570qh4444'
      },
      externalIdentifier: 'druid:zt570qh4444',
      label: 'My Admin Policy',
      type: Cocina::Models::ObjectType.admin_policy,
      version: 1
    )
  end
  let(:roles) do
    [
      {
        members: [
          { identifier: 'dlss:groupA', type: 'workgroup' },
          { identifier: 'dlss:groupB', type: 'workgroup' }
        ],
        name: 'dor-apo-depositor'
      },
      {
        members: [
          { identifier: 'dlss:groupA', type: 'workgroup' },
          { identifier: 'dlss:groupC', type: 'workgroup' }
        ],
        name: 'dor-apo-manager'
      }
    ]
  end

  describe '#admin?' do
    subject { user.admin? }

    let(:user) { described_class.new }

    before do
      allow(user).to receive(:groups).and_return(groups)
    end

    context 'when the group is a deprecated admin group' do
      let(:groups) { ['dlss:dor-admin'] }

      it { is_expected.to be false }
    end

    context 'when there are no groups' do
      let(:groups) { [] }

      it { is_expected.to be false }
    end

    context 'with an inadequate group membership' do
      let(:groups) { ['dlss:not-admin'] }

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

  describe '#webauth_admin?' do
    subject { user.webauth_admin? }

    let(:user) { described_class.new }

    before do
      allow(user).to receive(:webauth_groups).and_return(groups)
    end

    context 'with ADMIN_GROUPS' do
      let(:groups) { User::ADMIN_GROUPS }

      it { is_expected.to be true }
    end
  end

  describe '#sdr_api_authorized?' do
    subject { user.sdr_api_authorized? }

    let(:user) { described_class.new }

    before do
      allow(user).to receive(:webauth_groups).and_return(groups)
    end

    context 'with SDR_API_AUTHORIZED_GROUPS' do
      let(:groups) { User::SDR_API_AUTHORIZED_GROUPS }

      it { is_expected.to be true }
    end
  end

  describe '#manager?' do
    subject { user.manager? }

    let(:user) { described_class.new }

    before do
      allow(user).to receive(:groups).and_return(groups)
    end

    context 'when the group is a deprecated manager group' do
      let(:groups) { ['dlss:dor-manager'] }

      it { is_expected.to be false }
    end

    context 'when there are no groups' do
      let(:groups) { [] }

      it { is_expected.to be false }
    end

    context 'with an inadequate group membership' do
      let(:groups) { ['dlss:not-manager'] }

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

  describe '#viewer?' do
    subject { user.viewer? }

    let(:user) { described_class.new }

    before do
      allow(user).to receive(:groups).and_return(groups)
    end

    context 'when the group is a deprecated viewer group' do
      let(:groups) { ['dlss:dor-viewer'] }

      it { is_expected.to be false }
    end

    context 'when there are no groups' do
      let(:groups) { [] }

      it { is_expected.to be false }
    end

    context 'with an inadequate group membership' do
      let(:groups) { ['dlss:not-viewer'] }

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

  describe 'role_allowed' do
    before do
      allow(subject).to receive(:groups).and_return(['dlss:groupA'])
    end

    context 'when roles are defined in the APO' do
      it 'returns true when DOR solr document has a role with values that include a user group' do
        expect(subject.role_allowed?(admin_policy.administrative, 'dor-apo-depositor')).to be true
      end

      it 'returns false when the APO has a role with values that do not include a user group' do
        allow(subject).to receive(:groups).and_return(['dlss:groupX'])
        expect(subject.role_allowed?(admin_policy.administrative, 'dor-apo-depositor')).to be false
      end

      it 'returns false when the APO has no matching roles' do
        expect(subject.role_allowed?(admin_policy.administrative, 'sdr-administrator')).to be false
      end

      it 'returns false when user belongs to no groups' do
        allow(subject).to receive(:groups).and_return([])
        expect(subject.role_allowed?(admin_policy.administrative, 'dor-apo-depositor')).to be false
      end
    end

    context 'when there are no roles in the APO' do
      let(:roles) { [] }

      it 'returns false when the APO is empty' do
        expect(subject.role_allowed?(admin_policy.administrative, 'dor-apo-depositor')).to be false
      end
    end
  end

  describe 'roles' do
    let(:druid) { 'druid:zt570qh4444' }
    let(:object_client) { instance_double(Dor::Services::Client::Object, find: admin_policy) }

    before do
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    end

    it 'accepts any object identifier' do
      expect { subject.roles(druid) }.not_to raise_error
      expect { subject.roles('anyStringOK') }.not_to raise_error
    end

    it 'returns an empty array for any blank object identifier' do
      ['', nil].each do |pid|
        expect { subject.roles(pid) }.not_to raise_error
        expect(subject.roles(pid)).to be_empty
      end
    end

    it 'builds a set of roles from groups' do
      user_groups = %w[dlss:groupF dlss:groupA]
      user_roles = %w[dor-apo-depositor dor-apo-manager]
      expect(subject).to receive(:groups).and_return(user_groups).at_least(:once)
      expect(subject.roles(druid)).to eq(user_roles)
    end

    context 'when the admin policy is not found' do
      let(:admin_policy) { nil }

      it 'returns an empty set of roles if the APO is not found' do
        # check that the code will return immediately if solr doc is empty
        expect(subject).not_to receive(:groups)
        expect(subject).not_to receive(:role_allowed?)
        expect(subject.roles(druid)).to be_empty
      end
    end

    context 'when a user is named in a role' do
      let(:roles) do
        [
          {
            members: [
              { identifier: 'sunetid:tcramer', type: 'sunetid' }
            ],
            name: 'sdr-viewer'
          }
        ]
      end

      it 'works correctly if the individual is named in the apo, but is not in any groups that matter' do
        expect(subject).to receive(:groups).and_return(['sunetid:tcramer']).at_least(:once)
        expect(subject.roles(druid)).to eq(['sdr-viewer'])
      end
    end

    it 'hangs onto results through the life of the user object, avoiding multiple DSA queries to find the roles for the same pid multiple times' do
      expect(subject).to receive(:groups).and_return(['testdoesnotcarewhatishere']).at_least(:once)
      expect(object_client).to receive(:find).once
      subject.roles(druid)
      subject.roles(druid)
    end
  end

  describe '#groups' do
    subject { user.groups }

    let(:user) { build(:user, sunetid: 'asdf', webauth_groups:) }

    context 'when specified' do
      let(:webauth_groups) { %w[dlss:testgroup1 dlss:testgroup2 dlss:testgroup3] }

      it 'returns the groups by webauth' do
        expected_groups = ['sunetid:asdf'] + webauth_groups.map(&:to_s)
        expect(subject).to eq(expected_groups)
      end
    end

    describe 'impersonating' do
      let(:groups) { %w[dlss:impersonatedgroup1 dlss:impersonatedgroup2] }

      before do
        user.set_groups_to_impersonate(groups)
      end

      context 'when the groups include SDR_API_AUTHORIZED_GROUPS' do
        let(:groups) do
          %w[dlss:impersonatedgroup1 dlss:impersonatedgroup2] + User::SDR_API_AUTHORIZED_GROUPS
        end
        let(:webauth_groups) { User::ADMIN_GROUPS }

        it 'returns the impersonated groups excluding the SDR_API_AUTHORIZED_GROUPS' do
          expect(subject).not_to include User::SDR_API_AUTHORIZED_GROUPS.first
        end
      end

      context 'when the impersonating user is an admin' do
        let(:webauth_groups) { User::ADMIN_GROUPS }

        it 'returns only the impersonated groups' do
          expect(subject).not_to include User::ADMIN_GROUPS.first
        end
      end

      context 'when the impersonating user is an manager' do
        let(:webauth_groups) { User::MANAGER_GROUPS }

        it 'returns only the impersonated groups' do
          expect(subject).not_to include User::MANAGER_GROUPS.first
        end
      end

      context 'when the impersonating user is a viewer' do
        let(:webauth_groups) { User::VIEWER_GROUPS }

        it 'returns only the impersonated groups' do
          expect(subject).not_to include User::VIEWER_GROUPS.first
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

      let(:webauth_groups) { %w[dlss:testgroup1 dlss:testgroup2 dlss:testgroup3] }

      it 'returns the groups by webauth' do
        expected_groups = ['sunetid:asdf'] + webauth_groups.map(&:to_s)
        expect(subject).to eq(expected_groups)
      end
    end
  end

  describe 'set_groups_to_impersonate' do
    def groups_to_impersonate
      subject.instance_variable_get(:@groups_to_impersonate)
    end
    before do
      subject.instance_variable_set(:@groups_to_impersonate, %w[a b])
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
