# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dor::ObjectsController, type: :controller do
  before do
    sign_in(create(:user))

    allow(Dor).to receive(:find).with(pid).and_return(mock_object)
  end

  let(:pid) { 'druid:abc' }
  let(:mock_object) { instance_double(Dor::Item) }
  let(:workflow_service) { instance_double(Dor::Workflow::Client, create_workflow_by_name: nil) }
  let(:objects_client) { instance_double(Dor::Services::Client::Objects, register: dor_registration) }
  let(:object_client) { instance_double(Dor::Services::Client::Object, administrative_tags: administrative_tags) }
  let(:administrative_tags) { instance_double(Dor::Services::Client::AdministrativeTags, create: true) }
  let(:dor_registration) { instance_double(Cocina::Models::DRO, externalIdentifier: pid) }

  describe '#create' do
    before do
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
      allow(Dor::Services::Client).to receive(:objects).and_return(objects_client)
      allow(Dor::Workflow::Client).to receive(:new).and_return(workflow_service)
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

    context 'when register is successful with default rights' do
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
        expect(response).to be_created
        expect(objects_client).to have_received(:register).with(
          params: Cocina::Models::RequestDRO
        )
        expect(workflow_service).to have_received(:create_workflow_by_name)
          .with('druid:abc', 'registrationWF', version: '1')
      end
    end

    context 'when register is successful with location access' do
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
          rights: 'loc:music',
          source_id: 'foo:bar',
          other_id: 'label:'
        }
      end

      it 'registers the object' do
        post :create, params: submitted
        expect(response).to be_created
        expect(objects_client).to have_received(:register).with(
          params: Cocina::Models::RequestDRO
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
        post :create, params: {
          source_id: 'foo:bar',
          admin_policy: 'druid:hv992ry2431',
          rights: 'default',
          label: 'This things',
          other_id: 'label:',
          tag: ['Process : Content Type : Book (ltr)']
        }
        expect(response.status).to eq 409
        expect(response.body).to eq message
      end
    end
  end
end
