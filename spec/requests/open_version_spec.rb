# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Open a version', type: :request do
  let(:pid) { 'druid:bc123df4567' }
  let(:user) { create(:user) }
  let(:object_service) { instance_double(Dor::Services::Client::Object, find: cocina_model) }
  let(:cocina_model) do
    Cocina::Models.build({
                           'label' => 'My Item',
                           'version' => 2,
                           'type' => Cocina::Models::ObjectType.object,
                           'externalIdentifier' => pid,
                           'description' => {
                             'title' => [{ 'value' => 'My Item' }],
                             'purl' => "https://purl.stanford.edu/#{pid.delete_prefix('druid:')}"
                           },
                           'access' => {},
                           'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
                           'structural' => {},
                           'identification' => {}
                         })
  end

  before do
    allow(Argo::Indexer).to receive(:reindex_pid_remotely)
    allow(Dor::Services::Client).to receive(:object).and_return(object_service)
  end

  context 'when they have manage_item access' do
    before do
      sign_in user, groups: ['sdr:administrator-role']
    end

    let(:object_service) { instance_double(Dor::Services::Client::Object, version: version_client, find: cocina_model) }
    let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, open: true) }

    it 'calls dor-services to open a new version' do
      expect(Argo::Indexer).to receive(:reindex_pid_remotely)

      post "/items/#{pid}/versions/open", params: { significance: 'major', description: 'something' }

      expect(version_client).to have_received(:open).with(significance: 'major', description: 'something', opening_user_name: user.to_s)
    end
  end

  context 'without manage item access' do
    before do
      sign_in user
    end

    it 'returns a 403' do
      post "/items/#{pid}/versions/open", params: { significance: 'major', description: 'something' }

      expect(response.code).to eq('403')
    end
  end
end
