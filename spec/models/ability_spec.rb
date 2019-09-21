# frozen_string_literal: true

require 'rails_helper'
require 'cancan/matchers'

RSpec.describe Ability do
  let(:subject) { described_class.new(user) }
  let(:item) { Dor::Item.new(pid: 'x') }
  let(:user) do
    instance_double(User,
                    is_admin?: admin,
                    is_webauth_admin?: webauth_admin,
                    is_manager?: manager,
                    is_viewer?: viewer,
                    roles: roles)
  end
  let(:admin) { false }
  let(:webauth_admin) { false }
  let(:manager) { false }
  let(:viewer) { false }
  let(:roles) { [] }

  let(:new_apo_id) { 'new_apo_id' }
  let(:new_apo) { Dor::AdminPolicyObject.new(pid: new_apo_id) }

  let(:item_with_apo) { Dor::Item.new(pid: 'y') }

  before do
    allow(item_with_apo).to receive(:admin_policy_object).and_return(new_apo)
  end

  context 'as an administrator' do
    let(:admin) { true }

    it { is_expected.to be_able_to(:manage, :everything) }
    it { is_expected.to be_able_to(:manage_item, item) }
    it { is_expected.to be_able_to(:manage_desc_metadata, item) }
    it { is_expected.to be_able_to(:manage_governing_apo, item, new_apo_id) }
    it { is_expected.to be_able_to(:create, Dor::AdminPolicyObject) }
    it { is_expected.to be_able_to(:view_metadata, item) }
    it { is_expected.to be_able_to(:view_content, item) }
    it { is_expected.to be_able_to(:update, :workflow) }
  end

  context 'as a manager' do
    let(:manager) { true }

    it { is_expected.not_to be_able_to(:manage, :everything) }
    it { is_expected.to be_able_to(:manage_item, item) }
    it { is_expected.to be_able_to(:manage_desc_metadata, item) }
    it { is_expected.to be_able_to(:manage_governing_apo, item, new_apo_id) }
    it { is_expected.to be_able_to(:create, Dor::AdminPolicyObject) }
    it { is_expected.to be_able_to(:view_metadata, item) }
    it { is_expected.to be_able_to(:view_content, item) }
    it { is_expected.not_to be_able_to(:update, :workflow) }
  end

  context 'as a viewer' do
    let(:viewer) { true }

    it { is_expected.not_to be_able_to(:manage_item, item) }
    it { is_expected.not_to be_able_to(:manage_desc_metadata, item) }
    it { is_expected.not_to be_able_to(:create, Dor::AdminPolicyObject) }
    it { is_expected.not_to be_able_to(:manage_governing_apo, item, new_apo_id) }
    it { is_expected.to be_able_to(:view_metadata, item) }
    it { is_expected.to be_able_to(:view_content, item) }
    it { is_expected.not_to be_able_to(:update, :workflow) }
  end

  context 'for items without an APO' do
    it { is_expected.not_to be_able_to(:manage_item, item) }
    it { is_expected.not_to be_able_to(:manage_desc_metadata, item) }
    it { is_expected.not_to be_able_to(:manage_governing_apo, item, new_apo_id) }
    it { is_expected.not_to be_able_to(:view_content, item) }
    it { is_expected.not_to be_able_to(:view_metadata, item) }
  end

  context 'with the manage role' do
    let(:roles) { ['dor-administrator'] }

    it { is_expected.not_to be_able_to(:manage, :everything) }
    it { is_expected.not_to be_able_to(:manage_item, item) }
    it { is_expected.to be_able_to(:manage_item, item_with_apo) }
    it { is_expected.not_to be_able_to(:manage_governing_apo, item, new_apo_id) }
    it { is_expected.not_to be_able_to(:manage_desc_metadata, item) }
    it { is_expected.to be_able_to(:manage_desc_metadata, item_with_apo) }
    it { is_expected.not_to be_able_to(:create, Dor::AdminPolicyObject) }
    it { is_expected.not_to be_able_to(:view_metadata, item) }
    it { is_expected.to be_able_to(:view_metadata, item_with_apo) }
    it { is_expected.not_to be_able_to(:view_content, item) }
    it { is_expected.to be_able_to(:view_content, item_with_apo) }
  end

  context 'with the edit role' do
    let(:roles) { ['dor-apo-metadata'] }

    it { is_expected.not_to be_able_to(:manage, :everything) }
    it { is_expected.not_to be_able_to(:manage_item, item) }
    it { is_expected.not_to be_able_to(:manage_item, item_with_apo) }
    it { is_expected.not_to be_able_to(:manage_governing_apo, item, new_apo_id) }
    it { is_expected.not_to be_able_to(:manage_desc_metadata, item) }
    it { is_expected.to be_able_to(:manage_desc_metadata, item_with_apo) }
    it { is_expected.not_to be_able_to(:create, Dor::AdminPolicyObject) }
    it { is_expected.not_to be_able_to(:view_metadata, item) }
    it { is_expected.not_to be_able_to(:view_metadata, item_with_apo) }
    it { is_expected.not_to be_able_to(:view_content, item) }
    it { is_expected.not_to be_able_to(:view_content, item_with_apo) }
  end

  context 'with the view role' do
    let(:roles) { ['dor-viewer'] }

    it { is_expected.not_to be_able_to(:manage, :everything) }
    it { is_expected.not_to be_able_to(:manage_item, item) }
    it { is_expected.not_to be_able_to(:manage_item, item_with_apo) }
    it { is_expected.not_to be_able_to(:manage_desc_metadata, item) }
    it { is_expected.not_to be_able_to(:manage_governing_apo, item, new_apo_id) }
    it { is_expected.not_to be_able_to(:manage_desc_metadata, item_with_apo) }
    it { is_expected.not_to be_able_to(:create, Dor::AdminPolicyObject) }
    it { is_expected.not_to be_able_to(:view_metadata, item) }
    it { is_expected.to be_able_to(:view_metadata, item_with_apo) }
    it { is_expected.not_to be_able_to(:view_content, item) }
    it { is_expected.to be_able_to(:view_content, item_with_apo) }
  end
end
