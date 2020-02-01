# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dor::ObjectsController, type: :controller do
  before do
    sign_in(create(:user))

    allow(Dor).to receive(:find).with(dor_registration[:pid]).and_return(mock_object)
  end

  let(:mock_object) { instance_double(Dor::Item, update_index: true) }
  let(:workflow_service) { instance_double(Dor::Workflow::Client, create_workflow_by_name: nil) }
  let(:objects_client) { instance_double(Dor::Services::Client::Objects, register: dor_registration) }
  let(:dor_registration) { { pid: 'druid:abc' } }

  describe '#create' do
    before do
      allow(Dor::Services::Client).to receive(:objects).and_return(objects_client)
      allow(Dor::Config.workflow).to receive(:client).and_return(workflow_service)
    end

    context 'when source_id is not provided' do
      let(:submitted) do
        {
          object_type: 'item',
          admin_policy: 'druid:hv992ry2431',
          collection: 'druid:hv992ry7777',
          workflow_id: 'registrationWF',
          metadata_source: 'label',
          label: 'test parameters for registration',
          tag: ['Process : Content Type : Book (ltr)',
                'Registered By : jcoyne85'],
          rights: 'default',
          other_id: 'label:'
        }
      end

      it 'raises an error' do
        # this exception is handled by the Rails exception wrapper middleware in production
        expect { post :create, params: submitted }.to raise_error ActionController::ParameterMissing

        expect(objects_client).not_to have_received(:register)
        expect(workflow_service).not_to have_received(:create_workflow_by_name)
      end
    end

    context 'when register is successful' do
      let(:submitted) do
        {
          object_type: 'item',
          admin_policy: 'druid:hv992ry2431',
          collection: 'druid:hv992ry7777',
          workflow_id: 'registrationWF',
          metadata_source: 'label',
          label: 'test parameters for registration',
          tag: ['Process : Content Type : Book (ltr)',
                'Registered By : jcoyne85'],
          seed_datastream: ['descMetadata'],
          rights: 'default',
          source_id: 'foo:bar',
          other_id: 'label:'
        }
      end

      it 'registers the object' do
        post :create, params: submitted
        expect(response).to be_redirect
        expect(objects_client).to have_received(:register).with(
          params: {
            object_type: 'item',
            admin_policy: 'druid:hv992ry2431',
            collection: 'druid:hv992ry7777',
            metadata_source: 'label',
            label: 'test parameters for registration',
            tag: ['Process : Content Type : Book (ltr)',
                  'Registered By : jcoyne85'],
            seed_datastream: ['descMetadata'],
            rights: 'default',
            source_id: 'foo:bar',
            other_id: 'label:'
          }
        )
        expect(workflow_service).to have_received(:create_workflow_by_name)
          .with('druid:abc', 'registrationWF', version: '1')
      end
    end

    context 'when register is a conflict' do
      let(:message) { "Conflict: 409 (An object with the source ID 'sul:36105226711146' has already been registered" }

      before do
        allow(Dor::Services::Client.objects)
          .to receive(:register)
          .and_raise(Dor::Services::Client::UnexpectedResponse, message)
      end

      it 'shows an error' do
        post :create, params: { source_id: 'foo:bar', label: 'This things' }
        expect(response.status).to eq 409
        expect(response.body).to eq message
      end
    end
  end
end
