# frozen_string_literal: true

require 'rails_helper'
require 'cancan/matchers'

RSpec.describe Ability do
  subject(:ability) { described_class.new(user) }

  let(:dro) { build(:dro, id: new_cocina_object_id, admin_policy_id: apo_id) }
  let(:dro_with_metadata) { Cocina::Models.with_metadata(dro, '123') }
  let(:dro_lite) { Cocina::Models.build_lite(dro.to_h) }

  let(:admin_policy) { build(:admin_policy, id: new_cocina_object_id, admin_policy_id: apo_id) }
  let(:admin_policy_with_metadata) { Cocina::Models.with_metadata(admin_policy, '123') }
  let(:admin_policy_lite) { Cocina::Models.build_lite(admin_policy.to_h) }

  let(:collection) { build(:collection, id: new_cocina_object_id, admin_policy_id: apo_id) }
  let(:collection_with_metadata) { Cocina::Models.with_metadata(collection, '123') }
  let(:collection_lite) { Cocina::Models.build_lite(collection.to_h) }

  let(:user) do
    instance_double(User,
                    admin?: admin,
                    webauth_admin?: webauth_admin,
                    manager?: manager,
                    viewer?: viewer,
                    sdr_api_authorized?: sdr_api_authorized)
  end
  let(:admin) { false }
  let(:webauth_admin) { false }
  let(:manager) { false }
  let(:viewer) { false }
  let(:sdr_api_authorized) { false }
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
    it { is_expected.to be_able_to(:assign, :doi) }
    it { is_expected.not_to be_able_to(:create, :token) }
    it { is_expected.to be_able_to(:update, dro) }
    it { is_expected.to be_able_to(:manage_governing_apo, dro, apo_id) }
    it { is_expected.to be_able_to(:update, dro_with_metadata) }
    it { is_expected.to be_able_to(:manage_governing_apo, dro_with_metadata, apo_id) }
    it { is_expected.to be_able_to(:create, Cocina::Models::AdminPolicy) }
    it { is_expected.to be_able_to(:view_content, dro) }
    it { is_expected.to be_able_to(:view_content, dro_with_metadata) }
    it { is_expected.to be_able_to(:view_content, dro_lite) }
    it { is_expected.to be_able_to(:update, :workflow) }
  end

  context 'as a manager' do
    let(:manager) { true }

    it { is_expected.not_to be_able_to(:manage, :everything) }
    it { is_expected.not_to be_able_to(:assign, :doi) }
    it { is_expected.not_to be_able_to(:create, :token) }
    it { is_expected.to be_able_to(:update, dro) }
    it { is_expected.to be_able_to(:update, dro_with_metadata) }

    it { is_expected.to be_able_to(:manage_governing_apo, dro, apo_id) }
    it { is_expected.to be_able_to(:manage_governing_apo, dro_with_metadata, apo_id) }
    it { is_expected.to be_able_to(:create, Cocina::Models::AdminPolicy) }
    it { is_expected.to be_able_to(:view_content, dro) }
    it { is_expected.to be_able_to(:view_content, dro_with_metadata) }
    it { is_expected.to be_able_to(:view_content, dro_lite) }
    it { is_expected.not_to be_able_to(:update, :workflow) }
  end

  context 'as a viewer' do
    let(:viewer) { true }

    it { is_expected.not_to be_able_to(:assign, :doi) }
    it { is_expected.not_to be_able_to(:create, :token) }
    it { is_expected.not_to be_able_to(:update, dro) }
    it { is_expected.not_to be_able_to(:update, dro_with_metadata) }
    it { is_expected.not_to be_able_to(:create, Cocina::Models::AdminPolicy) }
    it { is_expected.not_to be_able_to(:manage_governing_apo, dro, apo_id) }
    it { is_expected.not_to be_able_to(:manage_governing_apo, dro_with_metadata, apo_id) }
    it { is_expected.to be_able_to(:read, dro) }
    it { is_expected.to be_able_to(:read, dro_with_metadata) }
    it { is_expected.to be_able_to(:read, dro_lite) }
    it { is_expected.to be_able_to(:view_content, dro) }
    it { is_expected.to be_able_to(:view_content, dro_with_metadata) }
    it { is_expected.to be_able_to(:view_content, dro_lite) }
    it { is_expected.to be_able_to(:read, admin_policy) }
    it { is_expected.to be_able_to(:read, admin_policy_with_metadata) }
    it { is_expected.to be_able_to(:read, admin_policy_lite) }
    it { is_expected.to be_able_to(:read, collection) }
    it { is_expected.to be_able_to(:read, collection_with_metadata) }
    it { is_expected.to be_able_to(:read, collection_lite) }
    it { is_expected.not_to be_able_to(:update, :workflow) }
  end

  context 'as a user authorized for SDR API' do
    let(:sdr_api_authorized) { true }

    it { is_expected.not_to be_able_to(:assign, :doi) }
    it { is_expected.to be_able_to(:create, :token) }
    it { is_expected.not_to be_able_to(:update, dro) }
    it { is_expected.not_to be_able_to(:update, dro_with_metadata) }
    it { is_expected.not_to be_able_to(:create, Cocina::Models::AdminPolicy) }
    it { is_expected.not_to be_able_to(:manage_governing_apo, dro, apo_id) }
    it { is_expected.not_to be_able_to(:manage_governing_apo, dro_with_metadata, apo_id) }
    it { is_expected.not_to be_able_to(:read, dro) }
    it { is_expected.not_to be_able_to(:read, dro_with_metadata) }
    it { is_expected.not_to be_able_to(:read, dro_lite) }
    it { is_expected.not_to be_able_to(:view_content, dro) }
    it { is_expected.not_to be_able_to(:view_content, dro_with_metadata) }
    it { is_expected.not_to be_able_to(:view_content, dro_lite) }
    it { is_expected.not_to be_able_to(:read, admin_policy) }
    it { is_expected.not_to be_able_to(:read, admin_policy_with_metadata) }
    it { is_expected.not_to be_able_to(:read, admin_policy_lite) }
    it { is_expected.not_to be_able_to(:read, collection) }
    it { is_expected.not_to be_able_to(:read, collection_with_metadata) }
    it { is_expected.not_to be_able_to(:read, collection_lite) }
    it { is_expected.not_to be_able_to(:update, :workflow) }
  end

  context 'for items without an APO' do
    it { is_expected.not_to be_able_to(:update, dro) }
    it { is_expected.not_to be_able_to(:update, dro_with_metadata) }
    it { is_expected.not_to be_able_to(:manage_governing_apo, dro, apo_id) }
    it { is_expected.not_to be_able_to(:manage_governing_apo, dro_with_metadata, apo_id) }
    it { is_expected.not_to be_able_to(:view_content, dro) }
    it { is_expected.not_to be_able_to(:view_content, dro_with_metadata) }
    it { is_expected.not_to be_able_to(:view_content, dro_lite) }
  end

  context 'with the manage role on the parent APO' do
    let(:apo_roles) { ['dor-apo-manager'] }

    it { is_expected.not_to be_able_to(:manage, :everything) }
    it { is_expected.not_to be_able_to(:assign, :doi) }
    it { is_expected.not_to be_able_to(:create, :token) }
    it { is_expected.to be_able_to(:update, dro) }
    it { is_expected.to be_able_to(:update, dro_with_metadata) }
    it { is_expected.to be_able_to(:manage_governing_apo, dro, apo_id) }
    it { is_expected.to be_able_to(:manage_governing_apo, dro_with_metadata, apo_id) }
    it { is_expected.not_to be_able_to(:create, Cocina::Models::AdminPolicy) }

    it { is_expected.to be_able_to(:read, dro) }
    it { is_expected.to be_able_to(:read, dro_with_metadata) }
    it { is_expected.to be_able_to(:read, dro_lite) }
    it { is_expected.to be_able_to(:read, collection) }
    it { is_expected.to be_able_to(:read, collection_with_metadata) }
    it { is_expected.to be_able_to(:read, collection_lite) }
    it { is_expected.to be_able_to(:read, admin_policy) }
    it { is_expected.to be_able_to(:read, admin_policy_with_metadata) }
    it { is_expected.to be_able_to(:read, admin_policy_lite) }
    it { is_expected.to be_able_to(:view_content, dro) }
    it { is_expected.to be_able_to(:view_content, dro_with_metadata) }
    it { is_expected.to be_able_to(:view_content, dro_lite) }
  end

  context 'with the manage role on the cocina_object' do
    let(:new_cocina_object_roles) { ['dor-apo-manager'] }

    it { is_expected.not_to be_able_to(:manage, :everything) }
    it { is_expected.not_to be_able_to(:assign, :doi) }
    it { is_expected.not_to be_able_to(:create, :token) }
    it { is_expected.not_to be_able_to(:update, dro) }
    it { is_expected.not_to be_able_to(:update, dro_with_metadata) }
    it { is_expected.not_to be_able_to(:manage_governing_apo, dro, apo_id) }
    it { is_expected.not_to be_able_to(:manage_governing_apo, dro_with_metadata, apo_id) }
    it { is_expected.not_to be_able_to(:create, Cocina::Models::AdminPolicy) }

    it { is_expected.not_to be_able_to(:read, dro) }
    it { is_expected.not_to be_able_to(:read, dro_with_metadata) }
    it { is_expected.not_to be_able_to(:read, dro_lite) }
    it { is_expected.not_to be_able_to(:read, collection) }
    it { is_expected.not_to be_able_to(:read, collection_with_metadata) }
    it { is_expected.not_to be_able_to(:read, collection_lite) }
    it { is_expected.to be_able_to(:read, admin_policy) }
    it { is_expected.to be_able_to(:read, admin_policy_with_metadata) }
    it { is_expected.to be_able_to(:read, admin_policy_lite) }
    it { is_expected.not_to be_able_to(:view_content, dro) }
    it { is_expected.not_to be_able_to(:view_content, dro_with_metadata) }
    it { is_expected.not_to be_able_to(:view_content, dro_lite) }
  end

  context 'with the edit role on the parent APO' do
    let(:apo_roles) { ['dor-apo-metadata'] }

    it { is_expected.not_to be_able_to(:manage, :everything) }
    it { is_expected.not_to be_able_to(:assign, :doi) }
    it { is_expected.not_to be_able_to(:create, :token) }
    it { is_expected.not_to be_able_to(:update, dro) }
    it { is_expected.not_to be_able_to(:update, dro_with_metadata) }
    it { is_expected.not_to be_able_to(:manage_governing_apo, dro, apo_id) }
    it { is_expected.not_to be_able_to(:manage_governing_apo, dro_with_metadata, apo_id) }
    it { is_expected.not_to be_able_to(:create, Cocina::Models::AdminPolicy) }
    it { is_expected.not_to be_able_to(:view_content, dro) }
    it { is_expected.not_to be_able_to(:view_content, dro_with_metadata) }
    it { is_expected.not_to be_able_to(:view_content, dro_lite) }
  end

  context 'with the view role on the parent APO' do
    let(:apo_roles) { ['dor-viewer'] }

    it { is_expected.not_to be_able_to(:manage, :everything) }
    it { is_expected.not_to be_able_to(:assign, :doi) }
    it { is_expected.not_to be_able_to(:create, :token) }
    it { is_expected.not_to be_able_to(:update, dro) }
    it { is_expected.not_to be_able_to(:update, dro_with_metadata) }
    it { is_expected.not_to be_able_to(:manage_governing_apo, dro, apo_id) }
    it { is_expected.not_to be_able_to(:manage_governing_apo, dro_with_metadata, apo_id) }
    it { is_expected.not_to be_able_to(:create, Cocina::Models::AdminPolicy) }
    it { is_expected.to be_able_to(:view_content, dro) }
    it { is_expected.to be_able_to(:view_content, dro_with_metadata) }
    it { is_expected.to be_able_to(:view_content, dro_lite) }
  end
end
