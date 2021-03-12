# frozen_string_literal: true

require 'rails_helper'
require 'cancan/matchers'

RSpec.describe Ability do
  let(:subject) { described_class.new(user) }
  let(:item) { Dor::Item.new(pid: 'x') }

  let(:dro) do
    Cocina::Models::DRO.new(externalIdentifier: 'druid:bc123df4567',
                            label: 'test',
                            type: Cocina::Models::Vocab.object,
                            version: 1,
                            access: {},
                            administrative: {
                              hasAdminPolicy: new_apo_id
                            })
  end

  let(:admin_policy) do
    Cocina::Models::AdminPolicy.new(externalIdentifier: new_apo_id,
                                    label: 'test',
                                    type: Cocina::Models::Vocab.admin_policy,
                                    version: 1,
                                    administrative: {
                                      hasAdminPolicy: new_apo_id
                                    })
  end

  let(:collection) do
    Cocina::Models::Collection.new(externalIdentifier: 'druid:bc123df4567',
                                   label: 'test',
                                   type: Cocina::Models::Vocab.collection,
                                   version: 1,
                                   access: {},
                                   administrative: {
                                     hasAdminPolicy: new_apo_id
                                   })
  end

  let(:user) do
    instance_double(User,
                    admin?: admin,
                    webauth_admin?: webauth_admin,
                    manager?: manager,
                    viewer?: viewer,
                    roles: roles)
  end
  let(:admin) { false }
  let(:webauth_admin) { false }
  let(:manager) { false }
  let(:viewer) { false }
  let(:roles) { [] }

  let(:new_apo_id) { 'druid:hv992yv2222' }
  let(:new_apo) { Dor::AdminPolicyObject.new(pid: new_apo_id) }

  let(:item_with_apo) { Dor::Item.new(pid: 'y') }

  before do
    allow(item_with_apo).to receive(:admin_policy_object).and_return(new_apo)
  end

  context 'as an administrator' do
    let(:admin) { true }

    it { is_expected.to be_able_to(:manage, :everything) }
    it { is_expected.to be_able_to(:manage_item, dro) }
    it { is_expected.to be_able_to(:manage_desc_metadata, dro) }
    it { is_expected.to be_able_to(:manage_governing_apo, dro, new_apo_id) }
    it { is_expected.to be_able_to(:create, Cocina::Models::AdminPolicy) }
    it { is_expected.to be_able_to(:view_content, dro) }
    it { is_expected.to be_able_to(:update, :workflow) }
  end

  context 'as a manager' do
    let(:manager) { true }

    it { is_expected.not_to be_able_to(:manage, :everything) }
    it { is_expected.to be_able_to(:manage_item, dro) }
    it { is_expected.to be_able_to(:manage_desc_metadata, dro) }

    it { is_expected.to be_able_to(:manage_governing_apo, dro, new_apo_id) }
    it { is_expected.to be_able_to(:create, Cocina::Models::AdminPolicy) }
    it { is_expected.to be_able_to(:view_content, dro) }
    it { is_expected.not_to be_able_to(:update, :workflow) }
  end

  context 'as a viewer' do
    let(:viewer) { true }

    it { is_expected.not_to be_able_to(:manage_item, dro) }
    it { is_expected.not_to be_able_to(:manage_desc_metadata, dro) }
    it { is_expected.not_to be_able_to(:create, Cocina::Models::AdminPolicy) }
    it { is_expected.not_to be_able_to(:manage_governing_apo, dro, new_apo_id) }
    it { is_expected.to be_able_to(:view_metadata, dro) }
    it { is_expected.to be_able_to(:view_content, dro) }
    it { is_expected.to be_able_to(:view_metadata, admin_policy) }
    it { is_expected.to be_able_to(:view_metadata, collection) }
    it { is_expected.not_to be_able_to(:update, :workflow) }
  end

  context 'for items without an APO' do
    it { is_expected.not_to be_able_to(:manage_item, dro) }
    it { is_expected.not_to be_able_to(:manage_desc_metadata, dro) }
    it { is_expected.not_to be_able_to(:manage_governing_apo, dro, new_apo_id) }
    it { is_expected.not_to be_able_to(:view_content, dro) }
  end

  context 'with the manage role' do
    let(:roles) { ['dor-apo-manager'] }

    it { is_expected.not_to be_able_to(:manage, :everything) }
    it { is_expected.to be_able_to(:manage_item, dro) }
    it { is_expected.to be_able_to(:manage_governing_apo, dro, new_apo_id) }
    it { is_expected.to be_able_to(:manage_desc_metadata, dro) }
    it { is_expected.not_to be_able_to(:create, Cocina::Models::AdminPolicy) }

    it { is_expected.to be_able_to(:view_metadata, dro) }
    it { is_expected.to be_able_to(:view_metadata, collection) }
    it { is_expected.to be_able_to(:view_metadata, admin_policy) }
    it { is_expected.to be_able_to(:view_content, dro) }
  end

  context 'with the edit role' do
    let(:roles) { ['dor-apo-metadata'] }

    it { is_expected.not_to be_able_to(:manage, :everything) }
    it { is_expected.not_to be_able_to(:manage_item, dro) }
    it { is_expected.not_to be_able_to(:manage_governing_apo, dro, new_apo_id) }
    it { is_expected.to be_able_to(:manage_desc_metadata, dro) }
    it { is_expected.not_to be_able_to(:create, Cocina::Models::AdminPolicy) }
    it { is_expected.not_to be_able_to(:view_content, dro) }
  end

  context 'with the view role' do
    let(:roles) { ['dor-viewer'] }

    it { is_expected.not_to be_able_to(:manage, :everything) }
    it { is_expected.not_to be_able_to(:manage_item, dro) }
    it { is_expected.not_to be_able_to(:manage_governing_apo, dro, new_apo_id) }
    it { is_expected.not_to be_able_to(:manage_desc_metadata, dro) }
    it { is_expected.not_to be_able_to(:create, Cocina::Models::AdminPolicy) }
    it { is_expected.to be_able_to(:view_content, dro) }
  end
end
