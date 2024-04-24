# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Apply APO defaults' do
  let(:druid) { 'druid:bc123df4567' }
  let(:user) { create(:user) }
  let(:object_client) do
    instance_double(Dor::Services::Client::Object, find: cocina_model, apply_admin_policy_defaults: true, reindex: true)
  end
  let(:cocina_model) { build(:dro_with_metadata, id: druid) }

  before do
    sign_in user
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
  end

  context 'when request succeeds' do
    it 'applies the defaults and redirects' do
      post "/items/#{druid}/apply_apo_defaults"
      expect(object_client).to have_received(:apply_admin_policy_defaults).once
      expect(object_client).to have_received(:reindex)
      expect(response).to redirect_to(solr_document_path(druid))
    end
  end
end
