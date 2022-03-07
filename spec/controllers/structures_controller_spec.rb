# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StructuresController do
  let(:user) { create(:user) }
  let(:pid) { 'druid:bc123df4567' }
  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model) }
  let(:state_service) { instance_double(StateService) }
  let(:successful_update) { double(success?: true, value!: Cocina::Models::DROStructural.new) }
  let(:file) { fixture_file_upload('structure-upload.csv') }
  let(:cocina_model) do
    Cocina::Models.build({
                           'label' => 'My Item',
                           'version' => 1,
                           'type' => Cocina::Models::Vocab.object,
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
    sign_in user
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    allow(controller).to receive(:authorize!).and_return(true)
    allow(StateService).to receive(:new).and_return(state_service)
    allow(StructureUpdater).to receive(:from_csv).and_return(successful_update)
    allow(object_client).to receive(:update)
  end

  describe '#update' do
    context 'object is unlocked' do
      before do
        allow(state_service).to receive(:allows_modification?).and_return(true)
      end

      it 'is successful' do
        put :update, params: { item_id: pid, csv: file }
        expect(StructureUpdater).to have_received(:from_csv)
        expect(object_client).to have_received(:update)
        expect(response).to have_http_status :redirect
      end
    end

    context 'object is locked' do
      before do
        allow(state_service).to receive(:allows_modification?).and_return(false)
      end

      it 'is not allowed' do
        put :update, params: { item_id: pid, csv: file }
        expect(StructureUpdater).not_to have_received(:from_csv)
        expect(object_client).not_to have_received(:update)
        expect(response).to have_http_status :redirect
        expect(flash[:error]).to eq 'Updates not allowed on this object.'
      end
    end
  end
end
