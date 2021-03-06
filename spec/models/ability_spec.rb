# frozen_string_literal: true

require 'rails_helper'
require 'cancan/matchers'

RSpec.describe Ability do
  subject(:ability) { described_class.new(user) }

  let(:dro) do
    Cocina::Models::DRO.new(externalIdentifier: new_cocina_object_id,
                            label: 'test',
                            type: Cocina::Models::Vocab.object,
                            version: 1,
                            access: {},
                            administrative: {
                              hasAdminPolicy: apo_id
                            })
  end

  let(:admin_policy) do
    Cocina::Models::AdminPolicy.new(externalIdentifier: new_cocina_object_id,
                                    label: 'test',
                                    type: Cocina::Models::Vocab.admin_policy,
                                    version: 1,
                                    administrative: {
                                      hasAdminPolicy: apo_id
                                    })
  end

  let(:collection) do
    Cocina::Models::Collection.new(externalIdentifier: new_cocina_object_id,
                                   label: 'test',
                                   type: Cocina::Models::Vocab.collection,
                                   version: 1,
                                   access: {},
                                   administrative: {
                                     hasAdminPolicy: apo_id
                                   })
  end

  let(:user) do
    instance_double(User,
                    admin?: admin,
                    webauth_admin?: webauth_admin,
                    manager?: manager,
                    viewer?: viewer)
  end
  let(:admin) { false }
  let(:webauth_admin) { false }
  let(:manager) { false }
  let(:viewer) { false }
  let(:new_cocina_object_roles) { [] }
  let(:apo_roles) { [] }
  let(:new_cocina_object_id) { 'druid:bc123df4567' }
  let(:apo_id) { 'druid:hv992yv2222' }

  before do
    allow(user).to receive(:roles).with(apo_id).and_return(apo_roles)
    allow(user).to receive(:roles).with(new_cocina_object_id).and_return(new_cocina_object_roles)
  end

  context 'as an administrator' do
    let(:admin) { true }

    it { is_expected.to be_able_to(:manage, :everything) }
    it { is_expected.to be_able_to(:manage_item, dro) }
    it { is_expected.to be_able_to(:manage_desc_metadata, dro) }
    it { is_expected.to be_able_to(:manage_governing_apo, dro, apo_id) }
    it { is_expected.to be_able_to(:create, Cocina::Models::AdminPolicy) }
    it { is_expected.to be_able_to(:view_content, dro) }
    it { is_expected.to be_able_to(:update, :workflow) }
  end

  context 'as a manager' do
    let(:manager) { true }

    it { is_expected.not_to be_able_to(:manage, :everything) }
    it { is_expected.to be_able_to(:manage_item, dro) }
    it { is_expected.to be_able_to(:manage_desc_metadata, dro) }

    it { is_expected.to be_able_to(:manage_governing_apo, dro, apo_id) }
    it { is_expected.to be_able_to(:create, Cocina::Models::AdminPolicy) }
    it { is_expected.to be_able_to(:view_content, dro) }
    it { is_expected.not_to be_able_to(:update, :workflow) }
  end

  context 'as a viewer' do
    let(:viewer) { true }

    it { is_expected.not_to be_able_to(:manage_item, dro) }
    it { is_expected.not_to be_able_to(:manage_desc_metadata, dro) }
    it { is_expected.not_to be_able_to(:create, Cocina::Models::AdminPolicy) }
    it { is_expected.not_to be_able_to(:manage_governing_apo, dro, apo_id) }
    it { is_expected.to be_able_to(:view_metadata, dro) }
    it { is_expected.to be_able_to(:view_content, dro) }
    it { is_expected.to be_able_to(:view_metadata, admin_policy) }
    it { is_expected.to be_able_to(:view_metadata, collection) }
    it { is_expected.not_to be_able_to(:update, :workflow) }
  end

  context 'for items without an APO' do
    it { is_expected.not_to be_able_to(:manage_item, dro) }
    it { is_expected.not_to be_able_to(:manage_desc_metadata, dro) }
    it { is_expected.not_to be_able_to(:manage_governing_apo, dro, apo_id) }
    it { is_expected.not_to be_able_to(:view_content, dro) }
  end

  context 'with the manage role on the parent APO' do
    let(:apo_roles) { ['dor-apo-manager'] }

    it { is_expected.not_to be_able_to(:manage, :everything) }
    it { is_expected.to be_able_to(:manage_item, dro) }
    it { is_expected.to be_able_to(:manage_governing_apo, dro, apo_id) }
    it { is_expected.to be_able_to(:manage_desc_metadata, dro) }
    it { is_expected.not_to be_able_to(:create, Cocina::Models::AdminPolicy) }

    it { is_expected.to be_able_to(:view_metadata, dro) }
    it { is_expected.to be_able_to(:view_metadata, collection) }
    it { is_expected.to be_able_to(:view_metadata, admin_policy) }
    it { is_expected.to be_able_to(:view_content, dro) }
  end

  context 'with the manage role on the cocina_object' do
    let(:new_cocina_object_roles) { ['dor-apo-manager'] }

    it { is_expected.not_to be_able_to(:manage, :everything) }
    it { is_expected.not_to be_able_to(:manage_item, dro) }
    it { is_expected.not_to be_able_to(:manage_governing_apo, dro, apo_id) }
    it { is_expected.not_to be_able_to(:manage_desc_metadata, dro) }
    it { is_expected.not_to be_able_to(:create, Cocina::Models::AdminPolicy) }

    it { is_expected.not_to be_able_to(:view_metadata, dro) }
    it { is_expected.not_to be_able_to(:view_metadata, collection) }
    it { is_expected.to be_able_to(:view_metadata, admin_policy) }
    it { is_expected.not_to be_able_to(:view_content, dro) }
  end

  context 'with the edit role on the parent APO' do
    let(:apo_roles) { ['dor-apo-metadata'] }

    it { is_expected.not_to be_able_to(:manage, :everything) }
    it { is_expected.not_to be_able_to(:manage_item, dro) }
    it { is_expected.not_to be_able_to(:manage_governing_apo, dro, apo_id) }
    it { is_expected.to be_able_to(:manage_desc_metadata, dro) }
    it { is_expected.not_to be_able_to(:create, Cocina::Models::AdminPolicy) }
    it { is_expected.not_to be_able_to(:view_content, dro) }
  end

  context 'with the view role on the parent APO' do
    let(:apo_roles) { ['dor-viewer'] }

    it { is_expected.not_to be_able_to(:manage, :everything) }
    it { is_expected.not_to be_able_to(:manage_item, dro) }
    it { is_expected.not_to be_able_to(:manage_governing_apo, dro, apo_id) }
    it { is_expected.not_to be_able_to(:manage_desc_metadata, dro) }
    it { is_expected.not_to be_able_to(:create, Cocina::Models::AdminPolicy) }
    it { is_expected.to be_able_to(:view_content, dro) }
  end
end
