# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Upload the structural CSV' do
  include Dry::Monads[:result]

  let(:user) { create(:user) }
  let(:druid) { 'druid:bc123df4567' }
  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model, update: true) }
  let(:state_service) { instance_double(StateService) }

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    allow(StateService).to receive(:new).and_return(state_service, allows_modification?: modifiable)
    allow(Argo::Indexer).to receive(:reindex_druid_remotely)
  end

  context 'when they have manage access' do
    before do
      allow(StructureUpdater).to receive(:from_csv).and_return(Success(cocina_model.structural))
      allow(state_service).to receive(:allows_modification?).and_return(modifiable)

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
                             'identification' => {}
                           })
    end
    let(:file) { fixture_file_upload('structure-upload.csv') }

    context 'when object is unlocked' do
      let(:modifiable) { true }

      it 'updates the structure' do
        put "/items/#{druid}/structure", params: { csv: file }
        expect(object_client).to have_received(:update)
        expect(response).to have_http_status(:see_other)
      end
    end

    context 'when object is locked' do
      let(:modifiable) { false }

      it 'updates the structure' do
        put "/items/#{druid}/structure", params: { csv: file }
        expect(object_client).not_to have_received(:update)
        expect(response).to have_http_status(:found)
      end
    end
  end
end
