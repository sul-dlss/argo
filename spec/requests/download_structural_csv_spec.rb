# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Download the structural CSV' do
  let(:user) { create(:user) }
  let(:pid) { 'druid:bc123df4567' }
  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model) }

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    allow(Argo::Indexer).to receive(:reindex_pid_remotely)
  end

  context 'when they have manage access' do
    before do
      allow(StructureSerializer).to receive(:as_csv).and_return('one,two,three')
      sign_in user, groups: ['sdr:administrator-role']
    end

    let(:cocina_model) do
      Cocina::Models.build({
                             'label' => 'My ETD',
                             'version' => 1,
                             'type' => Cocina::Models::Vocab.object,
                             'externalIdentifier' => pid,
                             'access' => {},
                             'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
                             'structural' => {},
                             'identification' => {}
                           })
    end

    it 'returns the csv' do
      get "/items/#{pid}/structure.csv"

      expect(response).to be_successful
      expect(response.body).to eq 'one,two,three'
    end
  end
end
