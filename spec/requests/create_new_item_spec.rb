# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create a new item', type: :request do
  let(:pid) { 'druid:abc' }
  let(:workflow_service) { instance_double(Dor::Workflow::Client, create_workflow_by_name: nil) }
  let(:object_client) { instance_double(Dor::Services::Client::Object, administrative_tags: administrative_tags) }
  let(:administrative_tags) { instance_double(Dor::Services::Client::AdministrativeTags, create: true) }
  let(:dor_registration) { instance_double(Cocina::Models::DRO, externalIdentifier: pid) }

  before do
    sign_in(create(:user))

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
      expect { post '/dor/objects', params: submitted }.to raise_error ActionController::ParameterMissing

      expect(workflow_service).not_to have_received(:create_workflow_by_name)
    end
  end

  context 'when barcode_id is provided' do
    let(:submitted) do
      {
        admin_policy: 'druid:hv992ry2431',
        workflow_id: 'registrationWF',
        label: 'test parameters for registration',
        tag: ['Process : Content Type : Book (ltr)',
              'Registered By : jcoyne85'],
        rights: 'default',
        other_id: 'label:',
        source_id: 'foo:bar',
        barcode_id: '36105010362304'
      }
    end

    it 'registers the object' do
      post '/dor/objects', params: submitted
      expect(response).to be_created
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
                              type: Cocina::Models::ObjectType.document,
                              label: 'Test DRO',
                              version: 1,
                              description: {
                                title: [{ value: 'Test DRO' }],
                                purl: 'https://purl.stanford.edu/bc234fg5678'
                              },
                              access: {},
                              administrative: {
                                hasAdminPolicy: 'druid:hv992ry2431'
                              }).to_json
    end

    let(:request_json) do
      "{\"cocinaVersion\":\"#{Cocina::Models::VERSION}\",\"type\":\"#{Cocina::Models::ObjectType.document}\"," \
        '"label":"test parameters for registration","version":1,"administrative":' \
        '{"hasAdminPolicy":"druid:hv992ry2431","releaseTags":[]},"identification":' \
        '{"catalogLinks":[],"sourceId":"foo:bar"},"structural":{"contains":[],"hasMemberOrders":[],' \
        '"isMemberOf":["druid:hv992ry7777"]}}'
    end

    before do
      stub_request(:post, "#{Settings.dor_services.url}/v1/objects")
        .with(body: request_json)
        .to_return(status: 200, body: json, headers: {})
    end

    it 'registers the object' do
      post '/dor/objects', params: submitted
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
                              type: Cocina::Models::ObjectType.image,
                              label: 'Test DRO',
                              version: 1,
                              description: {
                                title: [{ value: 'Test DRO' }],
                                purl: 'https://purl.stanford.edu/bc234fg5678'
                              },
                              access: {
                                view: 'stanford',
                                download: 'stanford'
                              },
                              administrative: {
                                hasAdminPolicy: 'druid:hv992ry2431'
                              }).to_json
    end
    let(:request_json) do
      "{\"cocinaVersion\":\"#{Cocina::Models::VERSION}\",\"type\":\"#{Cocina::Models::ObjectType.image}\"," \
        '"label":"test parameters for registration","version":1,"access":{"view":' \
        '"stanford","download":"stanford","location":null,"controlledDigitalLending":false},' \
        '"administrative":{"hasAdminPolicy":"druid:hv992ry2431","releaseTags":[]},"identification":' \
        '{"catalogLinks":[],"sourceId":"foo:bar"},"structural":{"contains":[],"hasMemberOrders":[],' \
        '"isMemberOf":["druid:hv992ry7777"]}}'
    end

    before do
      stub_request(:post, "#{Settings.dor_services.url}/v1/objects")
        .with(body: request_json)
        .to_return(status: 200, body: json, headers: {})
    end

    it 'registers the object' do
      post '/dor/objects', params: submitted
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
                              type: Cocina::Models::ObjectType.book,
                              label: 'Test DRO',
                              version: 1,
                              description: {
                                title: [{ value: 'Test DRO' }],
                                purl: 'https://purl.stanford.edu/bc234fg5678'
                              },
                              access: {
                                view: 'location-based',
                                download: 'location-based',
                                location: 'music'
                              },
                              administrative: {
                                hasAdminPolicy: 'druid:hv992ry2431'
                              }).to_json
    end

    let(:request_json) do
      "{\"cocinaVersion\":\"#{Cocina::Models::VERSION}\",\"type\":\"#{Cocina::Models::ObjectType.book}\"," \
        '"label":"test parameters for registration","version":1,"access":' \
        '{"view":"location-based","download":"location-based","location":' \
        '"music","controlledDigitalLending":false},"administrative":{"hasAdminPolicy":' \
        '"druid:hv992ry2431","releaseTags":[]},"identification":{"catalogLinks":[],' \
        '"sourceId":"foo:bar"},"structural":{"contains":[],"hasMemberOrders":[{"members":[],' \
        '"viewingDirection":"left-to-right"}],"isMemberOf":["druid:hv992ry7777"]}}'
    end

    before do
      stub_request(:post, "#{Settings.dor_services.url}/v1/objects")
        .with(body: request_json)
        .to_return(status: 200, body: json, headers: {})
    end

    it 'registers the object' do
      post '/dor/objects', params: submitted
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
                              type: Cocina::Models::ObjectType.image,
                              label: 'Test DRO',
                              version: 1,
                              description: {
                                title: [{ value: 'Test DRO' }],
                                purl: 'https://purl.stanford.edu/bc234fg5678'
                              },
                              access: {
                                view: 'world',
                                download: 'none'
                              },
                              administrative: {
                                hasAdminPolicy: 'druid:hv992ry2431'
                              }).to_json
    end

    let(:request_json) do
      "{\"cocinaVersion\":\"#{Cocina::Models::VERSION}\",\"type\":\"#{Cocina::Models::ObjectType.image}\"," \
        '"label":"test parameters for registration","version":1,"access":{"view":' \
        '"world","download":"none","location":null,"controlledDigitalLending":false},' \
        '"administrative":{"hasAdminPolicy":"druid:hv992ry2431","releaseTags":[]},"identification":' \
        '{"catalogLinks":[],"sourceId":"foo:bar"},"structural":{"contains":[],"hasMemberOrders":[],' \
        '"isMemberOf":["druid:hv992ry7777"]}}'
    end

    before do
      stub_request(:post, "#{Settings.dor_services.url}/v1/objects")
        .with(body: request_json)
        .to_return(status: 200, body: json, headers: {})
    end

    it 'registers the object' do
      post '/dor/objects', params: submitted
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
                              type: Cocina::Models::ObjectType.image,
                              label: 'Test DRO',
                              version: 1,
                              description: {
                                title: [{ value: 'Test DRO' }],
                                purl: 'https://purl.stanford.edu/bc234fg5678'
                              },
                              access: {
                                view: 'dark',
                                download: 'none'
                              },
                              administrative: {
                                hasAdminPolicy: 'druid:hv992ry2431'
                              }).to_json
    end

    let(:request_json) do
      "{\"cocinaVersion\":\"#{Cocina::Models::VERSION}\",\"type\":\"#{Cocina::Models::ObjectType.image}\"," \
        '"label":"test parameters for registration","version":1,"access":{"view":"dark",' \
        '"download":"none","location":null,"controlledDigitalLending":false},' \
        '"administrative":{"hasAdminPolicy":"druid:hv992ry2431","releaseTags":[]},' \
        '"identification":{"catalogLinks":[],"sourceId":"foo:bar"},"structural":{"contains":[],' \
        '"hasMemberOrders":[],"isMemberOf":["druid:hv992ry7777"]}}'
    end

    before do
      stub_request(:post, "#{Settings.dor_services.url}/v1/objects")
        .with(body: request_json)
        .to_return(status: 200, body: json, headers: {})
    end

    it 'registers the object' do
      post '/dor/objects', params: submitted
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
      post '/dor/objects', params: {
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
                              type: Cocina::Models::ObjectType.book,
                              label: 'Test DRO',
                              version: 1,
                              description: {
                                title: [{ value: 'Test DRO' }],
                                purl: 'https://purl.stanford.edu/bc234fg5678'
                              },
                              access: {
                                view: 'stanford',
                                download: 'none',
                                controlledDigitalLending: true
                              },
                              administrative: {
                                hasAdminPolicy: 'druid:hv992ry2431'
                              }).to_json
    end
    let(:request_json) do
      "{\"cocinaVersion\":\"#{Cocina::Models::VERSION}\",\"type\":\"#{Cocina::Models::ObjectType.book}\"," \
        '"label":"test parameters for registration","version":1,"access":' \
        '{"view":"stanford","download":"none","location":null,"controlledDigitalLending":true},' \
        '"administrative":{"hasAdminPolicy":"druid:hv992ry2431","releaseTags":[]},"identification":' \
        '{"catalogLinks":[],"sourceId":"foo:bar"},"structural":{"contains":[],"hasMemberOrders":' \
        '[{"members":[],"viewingDirection":"left-to-right"}],"isMemberOf":["druid:hv992ry7777"]}}'
    end

    before do
      stub_request(:post, "#{Settings.dor_services.url}/v1/objects")
        .with(body: request_json)
        .to_return(status: 200, body: json, headers: {})
    end

    it 'registers the object' do
      post '/dor/objects', params: submitted
      expect(response).to be_created
      expect(workflow_service).to have_received(:create_workflow_by_name)
        .with('druid:bc234fg5678', 'registrationWF', version: '1')
    end
  end
end
