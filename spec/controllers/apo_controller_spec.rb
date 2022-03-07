# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApoController, type: :controller do
  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    sign_in user
    allow(controller).to receive(:authorize!).with(:manage_item, Cocina::Models::AdminPolicy).and_return(true)
  end

  let(:user) { create(:user) }
  let(:pid) { 'druid:zt570qh4444' }
  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model) }
  let(:cocina_model) do
    Cocina::Models.build({
                           'label' => 'The APO',
                           'version' => 1,
                           'type' => Cocina::Models::Vocab.admin_policy,
                           'externalIdentifier' => pid,
                           'administrative' => {
                             hasAdminPolicy: 'druid:hv992ry2431',
                             hasAgreement: 'druid:hp308wm0436',
                             defaultAccess: { access: 'world', download: 'world' }
                           }
                         })
  end

  let(:collection_id) { 'druid:bq377wp9578' }
  let(:collection) do
    Cocina::Models::Collection.new(externalIdentifier: collection_id,
                                   type: Cocina::Models::Vocab.collection,
                                   label: '',
                                   version: 1,
                                   access: {})
  end

  describe '#delete_collection' do
    let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model, update: true) }
    let(:cocina_model) do
      Cocina::Models.build({
                             'label' => 'The APO',
                             'version' => 1,
                             'type' => Cocina::Models::Vocab.admin_policy,
                             'externalIdentifier' => pid,
                             'administrative' => {
                               hasAdminPolicy: 'druid:hv992ry2431',
                               hasAgreement: 'druid:hp308wm0436',
                               collectionsForRegistration: ['druid:1', collection_id],
                               defaultAccess: { access: 'world', download: 'world' }
                             }
                           })
    end

    let(:expected) do
      Cocina::Models.build({
                             'label' => 'The APO',
                             'version' => 1,
                             'type' => Cocina::Models::Vocab.admin_policy,
                             'externalIdentifier' => pid,
                             'administrative' => {
                               hasAdminPolicy: 'druid:hv992ry2431',
                               hasAgreement: 'druid:hp308wm0436',
                               collectionsForRegistration: ['druid:1'], # only one collection now
                               defaultAccess: { access: 'world', download: 'world' }
                             }
                           })
    end

    it 'calls remove_default_collection' do
      post 'delete_collection', params: { id: pid, collection: collection_id }
      expect(object_client).to have_received(:update)
        .with(params: expected)
    end
  end
end
