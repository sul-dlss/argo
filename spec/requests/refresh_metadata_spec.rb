# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Refresh metadata', type: :request do
  let(:druid) { 'druid:bc123df4567' }
  let(:state_service) { instance_double(StateService, allows_modification?: true) }
  let(:object_service) { instance_double(Dor::Services::Client::Object, refresh_metadata: true, find: cocina_model) }
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
                           'identification' => {
                             'catalogLinks' => catalog_links
                           }
                         })
  end
  let(:catalog_links) { [{ catalog: 'symphony', catalogRecordId: '12345' }] }

  before do
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_service)
    allow(StateService).to receive(:new).and_return(state_service)
  end

  context 'when they have manage access' do
    before do
      sign_in create(:user), groups: ['sdr:administrator-role']
    end

    context 'when the object has no catkey' do
      let(:catalog_links) { [] }

      it 'returns a 400 with an error message' do
        post "/items/#{druid}/refresh_metadata"

        expect(response).to have_http_status(:bad_request)
        expect(response.body).to eq 'object must have catkey to refresh descMetadata'
      end
    end

    context 'when a catkey is present' do
      it 'redirects with a notice if there is a catkey' do
        post "/items/#{druid}/refresh_metadata"
        expect(object_service).to have_received(:refresh_metadata)

        expect(response).to redirect_to solr_document_path(druid)
        expect(flash[:notice]).to eq "Metadata for #{druid} successfully refreshed from catkey: 12345"
      end
    end

    context "when the object doesn't allow modification" do
      let(:state_service) { instance_double(StateService, allows_modification?: false) }

      it 'redirects with an error message' do
        post "/items/#{druid}/refresh_metadata"
        expect(response).to redirect_to solr_document_path(druid)
        expect(flash[:error]).to eq 'Object cannot be modified in its current state.'
      end
    end
  end

  context 'when the user is not allowed to edit desc metadata' do
    before do
      sign_in create(:user), groups: []
    end

    it 'returns a 403 with an error message' do
      post "/items/#{druid}/refresh_metadata"

      expect(response).to have_http_status(:forbidden)
      expect(response.body).to eq 'forbidden'
    end
  end
end
