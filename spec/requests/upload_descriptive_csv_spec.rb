# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Upload the descriptive CSV' do
  include Dry::Monads[:result]

  let(:user) { create(:user) }
  let(:druid) { 'druid:bc123df4567' }
  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model, update: true) }
  let(:state_service) { instance_double(StateService) }

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    allow(Argo::Indexer).to receive(:reindex_druid_remotely)
  end

  context 'when they have manage access' do
    before do
      allow(DescriptionImport).to receive(:import).and_return(result)

      sign_in user, groups: ['sdr:administrator-role']
    end

    let(:cocina_model) do
      Cocina::Models.build({
                             'label' => 'My ETD',
                             'version' => 1,
                             'type' => Cocina::Models::ObjectType.object,
                             'externalIdentifier' => druid,
                             'description' => {
                               'title' => [{ 'value' => 'My ETD' }],
                               'purl' => "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}"
                             },
                             'access' => {},
                             'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
                             'structural' => {},
                             identification: { sourceId: 'sul:1234' }
                           })
    end
    let(:file) { fixture_file_upload('descriptive-upload.csv') }

    context 'when import was successful' do
      let(:result) { Success(cocina_model.description) }

      it 'updates the descriptive' do
        put "/items/#{druid}/descriptive", params: { data: file }
        expect(object_client).to have_received(:update)
        expect(response).to have_http_status(:see_other)
      end
    end

    context 'when import was not successful' do
      let(:result) { Failure(["didn't map"]) }

      it "doesn't updates the descriptive" do
        put "/items/#{druid}/descriptive", params: { data: file }
        expect(object_client).not_to have_received(:update)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
