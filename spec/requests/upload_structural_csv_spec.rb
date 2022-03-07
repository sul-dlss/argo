# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Upload the structural CSV' do
  include Dry::Monads[:result]

  let(:user) { create(:user) }
  let(:pid) { 'druid:bc123df4567' }
  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model, update: true) }

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    allow(Argo::Indexer).to receive(:reindex_pid_remotely)
  end

  context 'when they have manage access' do
    before do
      allow(StructureUpdater).to receive(:from_csv).and_return(Success(cocina_model.structural))
      sign_in user, groups: ['sdr:administrator-role']
    end

    let(:cocina_model) do
      Cocina::Models.build({
                             'label' => 'My ETD',
                             'version' => 1,
                             'type' => Cocina::Models::Vocab.object,
                             'externalIdentifier' => pid,
                             'description' => {
                               'title' => [{ 'value' => 'My ETD' }],
                               'purl' => "https://purl.stanford.edu/#{pid.delete_prefix('druid:')}"
                             },
                             'access' => {},
                             'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
                             'structural' => {},
                             'identification' => {}
                           })
    end
    let(:file) { fixture_file_upload('structure-upload.csv') }

    it 'updates the structure' do
      put "/items/#{pid}/structure", params: { csv: file }
      expect(object_client).to have_received(:update)
      expect(response).to have_http_status(:see_other)
    end
  end
end
