# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Apply APO defaults' do
  let(:pid) { 'druid:bc123df4567' }
  let(:user) { create(:user) }
  let(:object_client) do
    instance_double(Dor::Services::Client::Object, find: cocina_model, apply_admin_policy_defaults: true)
  end
  let(:cocina_model) do
    Cocina::Models.build({
                           'label' => 'The item',
                           'version' => 1,
                           'type' => Cocina::Models::ObjectType.object,
                           'externalIdentifier' => pid,
                           'description' => {
                             'title' => [{ 'value' => 'The item' }],
                             'purl' => "https://purl.stanford.edu/#{pid.delete_prefix('druid:')}"
                           },
                           'access' => {},
                           'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
                           'structural' => {},
                           'identification' => {}
                         })
  end

  before do
    sign_in user
    allow(Argo::Indexer).to receive(:reindex_pid_remotely)
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
  end

  context 'for bulk action requests' do
    context 'when request succeeds' do
      it 'applies the defaults' do
        post "/items/#{pid}/apply_apo_defaults?bulk=true"
        expect(object_client).to have_received(:apply_admin_policy_defaults).once
        expect(Argo::Indexer).not_to have_received(:reindex_pid_remotely).with(pid) # bulk actions do NOT reindex
        expect(response).to be_successful
      end
    end

    context 'when request errors' do
      before do
        allow(object_client).to receive(:apply_admin_policy_defaults).and_raise(Dor::Services::Client::UnexpectedResponse)
      end

      it 'renders an error message' do
        post "/items/#{pid}/apply_apo_defaults?bulk=true"
        expect(object_client).to have_received(:apply_admin_policy_defaults).once
        expect(Argo::Indexer).not_to have_received(:reindex_pid_remotely)
        expect(response).not_to be_successful
        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  context 'for action button requests' do
    context 'when request succeeds' do
      it 'applies the defaults and redirects' do
        post "/items/#{pid}/apply_apo_defaults"
        expect(object_client).to have_received(:apply_admin_policy_defaults).once
        expect(Argo::Indexer).to have_received(:reindex_pid_remotely).with(pid)
        expect(response).to redirect_to(solr_document_path(pid))
      end
    end
  end
end
