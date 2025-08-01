# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Update an existing Admin Policy' do
  let(:druid) { 'druid:bc123df4567' }
  let(:user) { create(:user) }
  let(:object_client) do
    instance_double(Dor::Services::Client::Object, find: cocina_model)
  end
  let(:cocina_model) { build(:admin_policy_with_metadata, id: druid) }

  before do
    sign_in user, groups: ['sdr:administrator-role']
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
  end

  context 'when the parameters are invalid' do
    it 'redraws the form' do
      patch "/apo/#{druid}", params: { apo: { title: '' } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  context 'when the parameters are valid' do
    let(:result) { cocina_model }
    let(:object_client) do
      instance_double(Dor::Services::Client::Object, find: cocina_model, update: result)
    end

    let(:objects_client) { instance_double(Dor::Services::Client::Objects, register: nil) }

    let(:params) do
      {
        apo: {
          title: 'my title',
          agreement_object_id: 'druid:dd327rv8888',
          view_access:,
          download_access:,
          access_location:,
          controlled_digital_lending:,
          default_workflows: ['registrationWF'],
          collection: { collection: '' }
        }
      }
    end

    before do
      allow(Dor::Services::Client).to receive(:objects).and_return(objects_client)
    end

    context 'with controlledDigitalLending' do
      let(:view_access) { 'stanford' }
      let(:download_access) { 'none' }
      let(:controlled_digital_lending) { '1' }
      let(:access_location) { nil }

      it 'updates the record and does not re-register' do
        patch("/apo/#{druid}", params:)
        expect(object_client).to have_received(:update)
        expect(objects_client).not_to have_received(:register)

        expect(response).to redirect_to solr_document_path(druid)
      end
    end

    context 'with citation-only' do
      let(:rights) { 'citation-only' }
      let(:view_access) { 'citation-only' }
      let(:download_access) { 'none' }
      let(:controlled_digital_lending) { '0' }
      let(:access_location) { nil }

      it 'updates the record and does not re-register' do
        patch("/apo/#{druid}", params:)
        expect(object_client).to have_received(:update)
        expect(objects_client).not_to have_received(:register)

        expect(response).to redirect_to solr_document_path(druid)
      end
    end
  end
end
