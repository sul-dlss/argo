# frozen_string_literal: true

require 'spec_helper'
require 'cancan/matchers'

describe Ability do
  let(:subject) { described_class.new(user) }
  let(:item) { Dor::Item.new(pid: 'x') }
  let(:user) do
    instance_double(User,
                    is_admin?: admin,
                    is_webauth_admin?: webauth_admin,
                    is_manager?: manager,
                    is_viewer?: viewer,
                    roles: [])
  end
  let(:admin) { false }
  let(:webauth_admin) { false }
  let(:manager) { false }
  let(:viewer) { false }

  let(:new_apo_id) { 'new_apo_id' }
  let(:new_apo) { Dor::AdminPolicyObject.new(pid: new_apo_id) }

  context 'as an administrator' do
    let(:admin) { true }

    it { is_expected.to be_able_to(:manage, :everything) }
    it { is_expected.to be_able_to(:manage_item, item) }
    it { is_expected.to be_able_to(:manage_content, item) }
    it { is_expected.to be_able_to(:manage_desc_metadata, item) }
    it { is_expected.to be_able_to(:manage_governing_apo, item, new_apo_id) }
    it { is_expected.to be_able_to(:create, Dor::AdminPolicyObject) }
    it { is_expected.to be_able_to(:view_metadata, item) }
    it { is_expected.to be_able_to(:view_content, item) }
  end

  context 'as a manager' do
    let(:manager) { true }

    it { is_expected.not_to be_able_to(:manage, :everything) }
    it { is_expected.to be_able_to(:manage_item, item) }
    it { is_expected.to be_able_to(:manage_content, item) }
    it { is_expected.to be_able_to(:manage_desc_metadata, item) }
    it { is_expected.to be_able_to(:manage_governing_apo, item, new_apo_id) }
    it { is_expected.to be_able_to(:create, Dor::AdminPolicyObject) }
    it { is_expected.to be_able_to(:view_metadata, item) }
    it { is_expected.to be_able_to(:view_content, item) }
  end

  context 'as a viewer' do
    let(:viewer) { true }

    it { is_expected.not_to be_able_to(:manage_item, item) }
    it { is_expected.not_to be_able_to(:manage_content, item) }
    it { is_expected.not_to be_able_to(:manage_desc_metadata, item) }
    it { is_expected.not_to be_able_to(:create, Dor::AdminPolicyObject) }
    it { is_expected.not_to be_able_to(:manage_governing_apo, item, new_apo_id) }
    it { is_expected.to be_able_to(:view_metadata, item) }
    it { is_expected.to be_able_to(:view_content, item) }
  end

  context 'for items without an APO' do
    it { is_expected.not_to be_able_to(:manage_item, item) }
    it { is_expected.not_to be_able_to(:manage_content, item) }
    it { is_expected.not_to be_able_to(:manage_desc_metadata, item) }
    it { is_expected.not_to be_able_to(:manage_governing_apo, item, new_apo_id) }
    it { is_expected.not_to be_able_to(:view_content, item) }
    it { is_expected.not_to be_able_to(:view_metadata, item) }
  end

  context 'from an APO' do
    let(:item) { Dor::AdminPolicyObject.new(pid: 'apo') }

    context 'for a user with a privileged role' do
      before do
        allow(user).to receive(:roles).with('apo').and_return(['recognized-and-permitted-role'])
        allow(Dor::Ability).to receive(:can_manage_item?).with(['recognized-and-permitted-role']).and_return(true)
      end

      it { is_expected.to be_able_to(:manage_item, item) }
    end

    context 'for a user without a role' do
      before do
        allow(user).to receive(:roles).with('apo').and_return(['some-other-role'])
        allow(Dor::Ability).to receive(:can_manage_item?).with(['some-other-role']).and_return(false)
      end

      it { is_expected.not_to be_able_to(:manage_item, item) }
    end
  end

  context 'with a role assigned by an APO' do
    let(:item) { Dor::Item.new(pid: 'x', admin_policy_object: apo) }
    let(:apo) { Dor::AdminPolicyObject.new(pid: 'apo') }
    let(:ungoverned_item) { Dor::Item.new(pid: 'y') }

    before do
      allow(user).to receive(:roles).with('apo').and_return(['recognized-and-permitted-role'])
      allow(user).to receive(:roles).with(new_apo_id).and_return(['target-apo-role'])
    end

    context 'as a user with a management role for an item' do
      before do
        allow(Dor::Ability).to receive(:can_manage_item?).with(['recognized-and-permitted-role']).and_return(true)
      end

      it { is_expected.not_to be_able_to(:manage_item, ungoverned_item) }
      it { is_expected.to be_able_to(:manage_item, item) }

      context 'and as a user with a management role for the target APO' do
        before { allow(Dor::Ability).to receive(:can_manage_item?).with(['target-apo-role']).and_return(true) }

        it { is_expected.to be_able_to(:manage_governing_apo, item, new_apo_id) }
      end

      context 'but as a user without a management role for the target APO' do
        before { allow(Dor::Ability).to receive(:can_manage_item?).with(['target-apo-role']).and_return(false) }

        it { is_expected.not_to be_able_to(:manage_governing_apo, item, new_apo_id) }
      end
    end

    context 'as a user with a content management role for an item' do
      before do
        allow(Dor::Ability).to receive(:can_manage_content?).with(['recognized-and-permitted-role']).and_return(true)
      end

      it { is_expected.not_to be_able_to(:manage_content, ungoverned_item) }
      it { is_expected.to be_able_to(:manage_content, item) }
    end

    context 'as a user with a metadata management role for an item' do
      before do
        allow(Dor::Ability).to receive(:can_manage_desc_metadata?).with(['recognized-and-permitted-role']).and_return(true)
      end

      it { is_expected.not_to be_able_to(:manage_desc_metadata, ungoverned_item) }
      it { is_expected.to be_able_to(:manage_desc_metadata, item) }
    end

    context 'as a user with a content viewer role for an item' do
      before do
        allow(Dor::Ability).to receive(:can_view_content?).with(['recognized-and-permitted-role']).and_return(true)
      end

      it { is_expected.not_to be_able_to(:view_content, ungoverned_item) }
      it { is_expected.to be_able_to(:view_content, item) }
    end

    context 'as a user with a metadata viewer role for an item' do
      before do
        allow(Dor::Ability).to receive(:can_view_metadata?).with(['recognized-and-permitted-role']).and_return(true)
      end

      it { is_expected.not_to be_able_to(:view_metadata, ungoverned_item) }
      it { is_expected.to be_able_to(:view_metadata, item) }
    end
  end

  context 'without a role assigned by an APO' do
    let(:item) { Dor::Item.new(pid: 'x', admin_policy_object: apo) }
    let(:apo) { Dor::AdminPolicyObject.new(pid: 'apo') }

    before do
      allow(user).to receive(:roles).with('apo').and_return(['some-other-role'])
      allow(user).to receive(:roles).with(new_apo_id).and_return(['target-apo-role'])
    end

    context 'as a user without a management role for an item' do
      before do
        allow(Dor::Ability).to receive(:can_manage_item?).with(['some-other-role']).and_return(false)
      end

      it { is_expected.not_to be_able_to(:manage_item, item) }

      context 'even as a user with a management role for the target APO' do
        before { allow(Dor::Ability).to receive(:can_manage_item?).with(['target-apo-role']).and_return(true) }

        it { is_expected.not_to be_able_to(:manage_governing_apo, item, new_apo_id) }
      end

      context 'as a user without a management role for the target APO either' do
        before { allow(Dor::Ability).to receive(:can_manage_item?).with(['target-apo-role']).and_return(false) }

        it { is_expected.not_to be_able_to(:manage_governing_apo, item, new_apo_id) }
      end
    end

    context 'as a user without a content management role for an item' do
      before do
        allow(Dor::Ability).to receive(:can_manage_content?).with(['some-other-role']).and_return(false)
      end

      it { is_expected.not_to be_able_to(:manage_content, item) }
    end

    context 'as a user without a metadata management role for an item' do
      before do
        allow(Dor::Ability).to receive(:can_manage_desc_metadata?).with(['some-other-role']).and_return(false)
      end

      it { is_expected.not_to be_able_to(:manage_desc_metadata, item) }
    end

    context 'as a user without a content viewer role for an item' do
      before do
        allow(Dor::Ability).to receive(:can_view_content?).with(['some-other-role']).and_return(false)
      end

      it { is_expected.not_to be_able_to(:view_content, item) }
    end

    context 'as a user without a metadata viewer role for an item' do
      before do
        allow(Dor::Ability).to receive(:can_view_metadata?).with(['some-other-role']).and_return(false)
      end

      it { is_expected.not_to be_able_to(:view_metadata, item) }
    end
  end
end
