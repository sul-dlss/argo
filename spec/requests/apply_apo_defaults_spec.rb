# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Apply APO defaults' do
  let(:druid) { 'druid:bc123df4567' }
  let(:user) { create(:user) }
  let(:object_client) do
    instance_double(Dor::Services::Client::Object, find: cocina_model, apply_admin_policy_defaults: true)
  end
  let(:cocina_model) do
    Cocina::Models.build({
                           'label' => 'The item',
                           'version' => 1,
                           'type' => Cocina::Models::ObjectType.object,
                           'externalIdentifier' => druid,
                           'description' => {
                             'title' => [{ 'value' => 'The item' }],
                             'purl' => "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}"
                           },
                           'access' => {},
                           'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
                           'structural' => {},
                           identification: { sourceId: 'sul:1234' }
                         })
  end

  before do
    sign_in user
    allow(Argo::Indexer).to receive(:reindex_druid_remotely)
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
  end

  context 'when request succeeds' do
    it 'applies the defaults and redirects' do
      post "/items/#{druid}/apply_apo_defaults"
      expect(object_client).to have_received(:apply_admin_policy_defaults).once
      expect(Argo::Indexer).to have_received(:reindex_druid_remotely).with(druid)
      expect(response).to redirect_to(solr_document_path(druid))
    end
  end
end
