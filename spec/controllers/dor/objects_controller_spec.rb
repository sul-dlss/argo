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
  let(:object_client) { instance_double(Dor::Services::Client::Object, administrative_tags: administrative_tags) }
  let(:administrative_tags) { instance_double(Dor::Services::Client::AdministrativeTags, create: true) }
  let(:dor_registration) { instance_double(Cocina::Models::DRO, externalIdentifier: pid) }

  describe '#create' do
    before do
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
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
          tag: ['Process : Content Type : Document',
                'Registered By : jcoyne85'],
          seed_datastream: ['descMetadata'],
          rights: 'default',
          source_id: 'foo:bar',
          other_id: 'label:'
        }
      end

      let(:json) do
        Cocina::Models::DRO.new(externalIdentifier: 'druid:bc234fg5678',
                                type: Cocina::Models::Vocab.document,
                                label: '',
                                version: 1,
                                access: {
                                  access: 'location-based'
                                }).to_json
      end

      before do
        stub_request(:post, 'http://localhost:3003/v1/objects')
          .with(
            body: '{"type":"http://cocina.sul.stanford.edu/models/document.jsonld",' \
            '"label":"test parameters for registration","version":1,' \
            '"administrative":{"hasAdminPolicy":"druid:hv992ry2431"},' \
            '"identification":{"sourceId":"foo:bar","catalogLinks":[]},' \
            '"structural":{"isMemberOf":"druid:hv992ry7777"}}'
          )
          .to_return(status: 200, body: json, headers: {})
      end

      it 'registers the object' do
        post :create, params: submitted
        expect(response).to be_created
        expect(workflow_service).to have_received(:create_workflow_by_name)
          .with('druid:bc234fg5678', 'registrationWF', version: '1')
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

      let(:json) do
        Cocina::Models::DRO.new(externalIdentifier: 'druid:bc234fg5678',
                                type: Cocina::Models::Vocab.book,
                                label: '',
                                version: 1,
                                access: {
                                  access: 'location-based'
                                }).to_json
      end

      before do
        stub_request(:post, 'http://localhost:3003/v1/objects')
          .with(
            body: '{"type":"http://cocina.sul.stanford.edu/models/book.jsonld",' \
            '"label":"test parameters for registration","version":1,' \
            '"access":{"access":"location-based","download":"none","readLocation":"music"},' \
            '"administrative":{"hasAdminPolicy":"druid:hv992ry2431"},' \
            '"identification":{"sourceId":"foo:bar","catalogLinks":[]},' \
            '"structural":{"hasMemberOrders":[{"viewingDirection":"left-to-right"}],' \
            '"isMemberOf":"druid:hv992ry7777"}}'
          )
          .to_return(status: 200, body: json, headers: {})
      end

      it 'registers the object' do
        post :create, params: submitted
        expect(response).to be_created
        expect(workflow_service).to have_received(:create_workflow_by_name)
          .with('druid:bc234fg5678', 'registrationWF', version: '1')
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
