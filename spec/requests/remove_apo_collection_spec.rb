# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Removing a collection from the registration list', type: :request do
  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    sign_in user, groups: ['sdr:administrator-role']
  end

  let(:user) { create(:user) }
  let(:druid) { 'druid:zt570qh4444' }
  let(:collection_id) { 'druid:bq377wp9578' }
  let(:collection) do
    Cocina::Models::Collection.new(externalIdentifier: collection_id,
                                   type: Cocina::Models::ObjectType.collection,
                                   label: '',
                                   version: 1,
                                   access: {})
  end

  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model, update: true) }
  let(:cocina_model) do
    Cocina::Models.build({
                           'label' => 'The APO',
                           'version' => 1,
                           'type' => Cocina::Models::ObjectType.admin_policy,
                           'externalIdentifier' => druid,
                           'administrative' => {
                             hasAdminPolicy: 'druid:hv992ry2431',
                             hasAgreement: 'druid:hp308wm0436',
                             collectionsForRegistration: ['druid:1', collection_id],
                             accessTemplate: { view: 'world', download: 'world' }
                           }
                         })
  end

  let(:expected) do
    Cocina::Models.build({
                           'label' => 'The APO',
                           'version' => 1,
                           'type' => Cocina::Models::ObjectType.admin_policy,
                           'externalIdentifier' => druid,
                           'administrative' => {
                             hasAdminPolicy: 'druid:hv992ry2431',
                             hasAgreement: 'druid:hp308wm0436',
                             collectionsForRegistration: ['druid:1'], # only one collection now
                             accessTemplate: { view: 'world', download: 'world' }
                           }
                         })
  end

  it 'calls remove_default_collection' do
    get "/apo/#{druid}/delete_collection?collection=#{collection_id}"
    expect(object_client).to have_received(:update)
      .with(params: expected)
  end
end
