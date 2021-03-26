# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dor::ObjectsController, type: :controller do
  before do
    sign_in(create(:user))
  end

  let(:pid) { 'druid:abc' }
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
          admin_policy: 'druid:hv992ry2431',
          collection: 'druid:hv992ry7777',
          workflow_id: 'registrationWF',
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
          admin_policy: 'druid:hv992ry2431',
          collection: 'druid:hv992ry7777',
          workflow_id: 'registrationWF',
          label: 'test parameters for registration',
          tag: ['Process : Content Type : Document',
                'Registered By : jcoyne85'],
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
                                },
                                administrative: {
                                  hasAdminPolicy: 'druid:hv992ry2431'
                                }).to_json
      end

      before do
        stub_request(:post, "#{Settings.dor_services.url}/v1/objects")
          .with(
            body: '{"type":"http://cocina.sul.stanford.edu/models/document.jsonld",' \
            '"label":"test parameters for registration","version":1,' \
            '"administrative":{"hasAdminPolicy":"druid:hv992ry2431"},' \
            '"identification":{"sourceId":"foo:bar","catalogLinks":[]},' \
            '"structural":{"isMemberOf":["druid:hv992ry7777"]}}'
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

    context 'when register is successful with explicit rights' do
      let(:submitted) do
        {
          admin_policy: 'druid:hv992ry2431',
          collection: 'druid:hv992ry7777',
          workflow_id: 'registrationWF',
          label: 'test parameters for registration',
          tag: ['Process : Content Type : Image',
                'Registered By : jcoyne85'],
          rights: 'stanford',
          source_id: 'foo:bar',
          other_id: 'label:'
        }
      end

      let(:json) do
        Cocina::Models::DRO.new(externalIdentifier: 'druid:bc234fg5678',
                                type: Cocina::Models::Vocab.image,
                                label: '',
                                version: 1,
                                access: {
                                  access: 'stanford',
                                  download: 'stanford',
                                  controlledDigitalLending: false
                                },
                                administrative: {
                                  hasAdminPolicy: 'druid:hv992ry2431'
                                }).to_json
      end

      before do
        stub_request(:post, "#{Settings.dor_services.url}/v1/objects")
          .with(
            body: '{"type":"http://cocina.sul.stanford.edu/models/image.jsonld",' \
            '"label":"test parameters for registration","version":1,' \
            '"access":{"access":"stanford","controlledDigitalLending":false,"download":"stanford"},' \
            '"administrative":{"hasAdminPolicy":"druid:hv992ry2431"},' \
            '"identification":{"sourceId":"foo:bar","catalogLinks":[]},' \
            '"structural":{"isMemberOf":["druid:hv992ry7777"]}}'
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
          admin_policy: 'druid:hv992ry2431',
          collection: 'druid:hv992ry7777',
          workflow_id: 'registrationWF',
          label: 'test parameters for registration',
          tag: ['Process : Content Type : Book (ltr)',
                'Registered By : jcoyne85'],
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
                                  access: 'location-based',
                                  controlledDigitalLending: false
                                },
                                administrative: {
                                  hasAdminPolicy: 'druid:hv992ry2431'
                                }).to_json
      end

      before do
        stub_request(:post, "#{Settings.dor_services.url}/v1/objects")
          .with(
            body: '{"type":"http://cocina.sul.stanford.edu/models/book.jsonld",' \
            '"label":"test parameters for registration","version":1,' \
            '"access":{"access":"location-based","controlledDigitalLending":false,"download":"location-based","readLocation":"music"},' \
            '"administrative":{"hasAdminPolicy":"druid:hv992ry2431"},' \
            '"identification":{"sourceId":"foo:bar","catalogLinks":[]},' \
            '"structural":{"hasMemberOrders":[{"viewingDirection":"left-to-right"}],' \
            '"isMemberOf":["druid:hv992ry7777"]}}'
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

    context 'when register is successful with no-download' do
      let(:submitted) do
        {
          admin_policy: 'druid:hv992ry2431',
          collection: 'druid:hv992ry7777',
          workflow_id: 'registrationWF',
          label: 'test parameters for registration',
          tag: ['Process : Content Type : Image',
                'Registered By : jcoyne85'],
          rights: 'world-nd',
          source_id: 'foo:bar',
          other_id: 'label:'
        }
      end

      let(:json) do
        Cocina::Models::DRO.new(externalIdentifier: 'druid:bc234fg5678',
                                type: Cocina::Models::Vocab.image,
                                label: '',
                                version: 1,
                                access: {
                                  access: 'world',
                                  download: 'none',
                                  controlledDigitalLending: false
                                },
                                administrative: {
                                  hasAdminPolicy: 'druid:hv992ry2431'
                                }).to_json
      end

      before do
        stub_request(:post, "#{Settings.dor_services.url}/v1/objects")
          .with(
            body: '{"type":"http://cocina.sul.stanford.edu/models/image.jsonld",' \
            '"label":"test parameters for registration","version":1,' \
            '"access":{"access":"world","controlledDigitalLending":false,"download":"none"},' \
            '"administrative":{"hasAdminPolicy":"druid:hv992ry2431"},' \
            '"identification":{"sourceId":"foo:bar","catalogLinks":[]},' \
            '"structural":{"isMemberOf":["druid:hv992ry7777"]}}'
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

    context 'when register is successful with dark' do
      let(:submitted) do
        {
          admin_policy: 'druid:hv992ry2431',
          collection: 'druid:hv992ry7777',
          workflow_id: 'registrationWF',
          label: 'test parameters for registration',
          tag: ['Process : Content Type : Image',
                'Registered By : jcoyne85'],
          rights: 'dark',
          source_id: 'foo:bar',
          other_id: 'label:'
        }
      end

      let(:json) do
        Cocina::Models::DRO.new(externalIdentifier: 'druid:bc234fg5678',
                                type: Cocina::Models::Vocab.image,
                                label: '',
                                version: 1,
                                access: {
                                  access: 'world',
                                  download: 'none',
                                  controlledDigitalLending: false
                                },
                                administrative: {
                                  hasAdminPolicy: 'druid:hv992ry2431'
                                }).to_json
      end

      before do
        stub_request(:post, "#{Settings.dor_services.url}/v1/objects")
          .with(
            body: '{"type":"http://cocina.sul.stanford.edu/models/image.jsonld",' \
            '"label":"test parameters for registration","version":1,' \
            '"access":{"access":"dark","controlledDigitalLending":false,"download":"none"},' \
            '"administrative":{"hasAdminPolicy":"druid:hv992ry2431"},' \
            '"identification":{"sourceId":"foo:bar","catalogLinks":[]},' \
            '"structural":{"isMemberOf":["druid:hv992ry7777"]}}'
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

    context 'when register is successful with controlled digital lending' do
      let(:submitted) do
        {
          admin_policy: 'druid:hv992ry2431',
          collection: 'druid:hv992ry7777',
          workflow_id: 'registrationWF',
          label: 'test parameters for registration',
          tag: ['Process : Content Type : Book (ltr)',
                'Registered By : jcoyne85'],
          rights: 'cdl-stanford-nd',
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
                                  access: 'citation-only',
                                  download: 'none',
                                  controlledDigitalLending: true
                                },
                                administrative: {
                                  hasAdminPolicy: 'druid:hv992ry2431'
                                }).to_json
      end

      before do
        stub_request(:post, "#{Settings.dor_services.url}/v1/objects")
          .with(
            body: '{"type":"http://cocina.sul.stanford.edu/models/book.jsonld",' \
        '"label":"test parameters for registration","version":1,' \
        '"access":{"access":"citation-only","controlledDigitalLending":true,"download":"none"},' \
        '"administrative":{"hasAdminPolicy":"druid:hv992ry2431"},' \
        '"identification":{"sourceId":"foo:bar","catalogLinks":[]},' \
        '"structural":{"hasMemberOrders":[{"viewingDirection":"left-to-right"}],' \
        '"isMemberOf":["druid:hv992ry7777"]}}'
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
  end
end
