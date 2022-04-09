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
    build(:collection, id: collection_id)
  end

  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model, update: true) }
  let(:cocina_model) do
    build(:admin_policy, collections_for_registration: ['druid:1', collection_id])
  end

  let(:expected) do
    build(:admin_policy, collections_for_registration: ['druid:1']) # only one collection now
  end

  it 'calls remove_default_collection' do
    get "/apo/#{druid}/delete_collection?collection=#{collection_id}"
    expect(object_client).to have_received(:update)
      .with(params: expected)
  end
end
