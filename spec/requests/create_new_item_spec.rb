# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create a new item' do
  let(:druid) { 'druid:abc' }
  let(:workflow_client) { instance_double(Dor::Services::Client::ObjectWorkflow, create: nil) }
  let(:object_client) { instance_double(Dor::Services::Client::Object, administrative_tags:, workflow: workflow_client) }
  let(:administrative_tags) { instance_double(Dor::Services::Client::AdministrativeTags, create: true) }
  let(:dor_registration) { instance_double(Cocina::Models::DRO, externalIdentifier: druid) }
  let(:headers) do
    {
      'Last-Modified' => 'Wed, 03 Mar 2021 18:58:00 GMT',
      'X-Created-At' => 'Wed, 01 Jan 2021 12:58:00 GMT',
      'X-Served-By' => 'Awesome webserver',
      'ETag' => 'W/"d41d8cd98f00b204e9800998ecf8427e"'
    }
  end

  before do
    sign_in(create(:user))
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
  end

  context 'when source_id is not provided' do
    let(:submitted) do
      {
        registration: {
          admin_policy: 'druid:hv992ry2431',
          collection: 'druid:hv992ry7777',
          workflow_id: 'registrationWF',
          tag: ['Registered By : jcoyne85'],
          view_access: 'world',
          download_access: 'world',
          content_type: 'https://cocina.sul.stanford.edu/models/book',
          items: [
            {
              source_id: '',
              label: 'test parameters for registration'
            }
          ]
        }
      }
    end

    before do
      allow(AdminPolicyOptions).to receive(:for).and_return(['APO 1', 'APO 2', 'APO 3'])
    end

    it 'displays an error' do
      post '/registration', params: submitted
      expect(response.body).to include 'Source ID is invalid'

      expect(workflow_client).not_to have_received(:create)
    end
  end

  context 'when workflow_id is missing' do
    before do
      allow(AdminPolicyOptions).to receive(:for).and_return(['APO 1', 'APO 2', 'APO 3'])
    end

    it 'shows an error' do
      post '/registration', params: {
        registration: {
          admin_policy: 'druid:hv992ry2431',
          view_access: 'world',
          download_access: 'world',
          controlled_digital_lending: 'false',
          workflow_id: nil,
          content_type: 'https://cocina.sul.stanford.edu/models/book',
          items: [
            {
              source_id: 'foo:bar',
              label: 'This things'
            }
          ],
          tag: ['Registered By : jcoyne85']
        }
      }
      expect(response).to have_http_status :bad_request
      expect(response.body).to include 'Workflow can&#39;t be blank'
    end
  end

  context 'when barcode_id is provided' do
    let(:source_id) { "sul:#{SecureRandom.uuid}" }
    let(:submitted) do
      {
        registration: {
          admin_policy: 'druid:hv992ry2431',
          workflow_id: 'registrationWF',
          tag: ['Registered By : jcoyne85'],
          view_access: 'world',
          download_access: 'world',
          controlled_digital_lending: 'false',
          content_type: 'https://cocina.sul.stanford.edu/models/book',
          items: [
            {
              source_id:,
              barcode_id: '36105010362304',
              label: 'test parameters for registration'
            }
          ]
        }
      }
    end

    it 'registers the object' do
      post '/registration', params: submitted

      expect(response).to have_http_status(:ok)
    end
  end

  context 'when register is successful with default rights' do
    let(:submitted) do
      {
        registration: {
          admin_policy: 'druid:hv992ry2431',
          collection: 'druid:hv992ry7777',
          workflow_id: 'registrationWF',
          tag: ['Registered By : jcoyne85'],
          view_access: 'world',
          download_access: 'world',
          controlled_digital_lending: 'false',
          content_type: 'https://cocina.sul.stanford.edu/models/document',
          items: [
            {
              source_id: 'foo:bar',
              label: 'test parameters for registration'
            }
          ]
        }
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
                              identification: { sourceId: 'sul:1234' },
                              structural: {},
                              administrative: {
                                hasAdminPolicy: 'druid:hv992ry2431'
                              }).to_json
    end

    let(:request_json) do
      "{\"cocinaVersion\":\"#{Cocina::Models::VERSION}\",\"type\":\"#{Cocina::Models::ObjectType.document}\"," \
        '"label":"test parameters for registration","version":1,' \
        '"access":{"view":"world","download":"world","controlledDigitalLending":false},' \
        '"administrative":' \
        '{"hasAdminPolicy":"druid:hv992ry2431"},"identification":' \
        '{"catalogLinks":[],"sourceId":"foo:bar"},"structural":{"contains":[],"hasMemberOrders":[],' \
        '"isMemberOf":["druid:hv992ry7777"]}}'
    end

    before do
      stub_request(:post, "#{Settings.dor_services.url}/v1/objects?assign_doi=false")
        .with(body: request_json)
        .to_return(status: 200, body: json, headers:)
    end

    it 'registers the object' do
      post '/registration', params: submitted
      expect(response).to have_http_status(:ok)
      expect(workflow_client).to have_received(:create).with(version: '1')
    end
  end

  context 'when register is successful with explicit rights' do
    let(:submitted) do
      {
        registration: {
          admin_policy: 'druid:hv992ry2431',
          collection: 'druid:hv992ry7777',
          workflow_id: 'registrationWF',
          tag: ['Registered By : jcoyne85'],
          view_access: 'stanford',
          download_access: 'stanford',
          controlled_digital_lending: 'false',
          content_type: 'https://cocina.sul.stanford.edu/models/image',
          items: [
            {
              source_id: 'foo:bar',
              label: 'test parameters for registration'
            }
          ]
        }
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
                              identification: { sourceId: 'sul:1234' },
                              structural: {},
                              administrative: {
                                hasAdminPolicy: 'druid:hv992ry2431'
                              }).to_json
    end
    let(:request_json) do
      "{\"cocinaVersion\":\"#{Cocina::Models::VERSION}\",\"type\":\"#{Cocina::Models::ObjectType.image}\"," \
        '"label":"test parameters for registration","version":1,' \
        '"access":{"view":"stanford","download":"stanford","controlledDigitalLending":false},' \
        '"administrative":{"hasAdminPolicy":"druid:hv992ry2431"},"identification":' \
        '{"catalogLinks":[],"sourceId":"foo:bar"},"structural":{"contains":[],"hasMemberOrders":[],' \
        '"isMemberOf":["druid:hv992ry7777"]}}'
    end

    before do
      stub_request(:post, "#{Settings.dor_services.url}/v1/objects?assign_doi=false")
        .with(body: request_json)
        .to_return(status: 200, body: json, headers:)
    end

    it 'registers the object' do
      post '/registration', params: submitted
      expect(response).to have_http_status(:ok)
      expect(workflow_client).to have_received(:create)
        .with(version: '1')
    end
  end

  context 'when register is successful with location access' do
    let(:submitted) do
      {
        registration: {

          admin_policy: 'druid:hv992ry2431',
          collection: 'druid:hv992ry7777',
          workflow_id: 'registrationWF',
          tag: ['Registered By : jcoyne85'],
          view_access: 'location-based',
          download_access: 'location-based',
          access_location: 'music',
          controlled_digital_lending: 'false',
          content_type: 'https://cocina.sul.stanford.edu/models/book',
          viewing_direction: 'left-to-right',
          items: [
            {
              source_id: 'foo:bar',
              label: 'test parameters for registration'
            }
          ]
        }
      }
    end

    let(:json) do
      Cocina::Models::DRO.new(externalIdentifier: 'druid:bc234fg5678',
                              type: Cocina::Models::ObjectType.book,
                              label: 'Test DRO',
                              version: 1,
                              description: {
                                title: [{ value: 'xTest DRO' }],
                                purl: 'https://purl.stanford.edu/bc234fg5678'
                              },
                              access: {
                                view: 'location-based',
                                download: 'location-based',
                                location: 'music'
                              },
                              identification: { sourceId: 'sul:1234' },
                              structural: {
                                hasMemberOrders: [
                                  viewingDirection: 'left-to-right'
                                ]
                              },
                              administrative: {
                                hasAdminPolicy: 'druid:hv992ry2431'
                              }).to_json
    end

    let(:request_json) do
      "{\"cocinaVersion\":\"#{Cocina::Models::VERSION}\",\"type\":\"#{Cocina::Models::ObjectType.book}\"," \
        '"label":"test parameters for registration","version":1,' \
        '"access":{"view":"location-based","download":"location-based","location":' \
        '"music","controlledDigitalLending":false},' \
        '"administrative":{"hasAdminPolicy":"druid:hv992ry2431"},' \
        '"identification":{"catalogLinks":[],"sourceId":"foo:bar"},' \
        '"structural":{"contains":[],"hasMemberOrders":[{"members":[],' \
        '"viewingDirection":"left-to-right"}],"isMemberOf":["druid:hv992ry7777"]}}'
    end

    before do
      stub_request(:post, "#{Settings.dor_services.url}/v1/objects?assign_doi=false")
        .with(body: request_json)
        .to_return(status: 200, body: json, headers:)
    end

    it 'registers the object' do
      post '/registration', params: submitted
      expect(response).to have_http_status(:ok)
      expect(workflow_client).to have_received(:create)
        .with(version: '1')
    end
  end

  context 'when register is successful with no-download and viewing direction set RTL' do
    let(:submitted) do
      {
        registration: {
          admin_policy: 'druid:hv992ry2431',
          collection: 'druid:hv992ry7777',
          workflow_id: 'registrationWF',
          tag: ['Registered By : jcoyne85'],
          view_access: 'world',
          download_access: 'none',
          controlled_digital_lending: 'false',
          content_type: 'https://cocina.sul.stanford.edu/models/image',
          viewing_direction: 'right-to-left',
          items: [
            {
              source_id: 'foo:bar',
              label: 'test parameters for registration'
            }
          ]
        }
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
                              identification: { sourceId: 'sul:1234' },
                              structural: {
                                hasMemberOrders: [
                                  viewingDirection: 'right-to-left'
                                ]
                              },
                              administrative: {
                                hasAdminPolicy: 'druid:hv992ry2431'
                              }).to_json
    end

    let(:request_json) do
      "{\"cocinaVersion\":\"#{Cocina::Models::VERSION}\",\"type\":\"#{Cocina::Models::ObjectType.image}\"," \
        '"label":"test parameters for registration","version":1,' \
        '"access":{"view":"world","download":"none","controlledDigitalLending":false},' \
        '"administrative":{"hasAdminPolicy":"druid:hv992ry2431"},"identification":' \
        '{"catalogLinks":[],"sourceId":"foo:bar"},"structural":{"contains":[],"hasMemberOrders":[{"members":[],' \
        '"viewingDirection":"right-to-left"}],"isMemberOf":["druid:hv992ry7777"]}}'
    end

    before do
      stub_request(:post, "#{Settings.dor_services.url}/v1/objects?assign_doi=false")
        .with(body: request_json)
        .to_return(status: 200, body: json, headers:)
    end

    it 'registers the object' do
      post '/registration', params: submitted
      expect(response).to have_http_status(:ok)
      expect(workflow_client).to have_received(:create)
        .with(version: '1')
    end
  end

  context 'when register is successful with dark' do
    let(:submitted) do
      {
        registration: {
          admin_policy: 'druid:hv992ry2431',
          collection: 'druid:hv992ry7777',
          workflow_id: 'registrationWF',
          items: [
            {
              source_id: 'foo:bar',
              label: 'test parameters for registration'
            }
          ],
          tag: ['Registered By : jcoyne85'],
          view_access: 'dark',
          controlled_digital_lending: 'false',
          content_type: 'https://cocina.sul.stanford.edu/models/image'
        }
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
                              identification: { sourceId: 'sul:1234' },
                              structural: {},
                              administrative: {
                                hasAdminPolicy: 'druid:hv992ry2431'
                              }).to_json
    end

    let(:request_json) do
      "{\"cocinaVersion\":\"#{Cocina::Models::VERSION}\",\"type\":\"#{Cocina::Models::ObjectType.image}\"," \
        '"label":"test parameters for registration","version":1,' \
        '"access":{"view":"dark","download":"none","controlledDigitalLending":false},' \
        '"administrative":{"hasAdminPolicy":"druid:hv992ry2431"},' \
        '"identification":{"catalogLinks":[],"sourceId":"foo:bar"},"structural":{"contains":[],' \
        '"hasMemberOrders":[],"isMemberOf":["druid:hv992ry7777"]}}'
    end

    before do
      stub_request(:post, "#{Settings.dor_services.url}/v1/objects?assign_doi=false")
        .with(body: request_json)
        .to_return(status: 200, body: json, headers:)
    end

    it 'registers the object' do
      post '/registration', params: submitted
      expect(response).to have_http_status(:ok)
      expect(workflow_client).to have_received(:create)
        .with(version: '1')
    end
  end

  context 'when register is a conflict' do
    let(:json_response) do
      <<~JSON
        {"errors":
          [{
            "status":"422",
            "title":"Conflict",
            "detail":"An object (druid:abc123) with the source ID 'googlebooks:999999' has already been registered."
          }]
        }
      JSON
    end

    before do
      stub_request(:post, "#{Settings.dor_services.url}/v1/objects?assign_doi=false")
        .to_return(status: 409, body: json_response, headers: { 'content-type' => 'application/vnd.api+json' })
      allow(AdminPolicyOptions).to receive(:for).and_return(['APO 1', 'APO 2', 'APO 3'])
    end

    it 'shows an error' do
      post '/registration', params: {
        registration: {
          admin_policy: 'druid:hv992ry2431',
          view_access: 'world',
          download_access: 'world',
          controlled_digital_lending: 'false',
          workflow_id: 'registrationWF',
          content_type: 'https://cocina.sul.stanford.edu/models/book',
          items: [
            {
              source_id: 'foo:bar',
              label: 'This things'
            }
          ],
          tag: ['Registered By : jcoyne85']
        }
      }
      expect(response).to have_http_status :bad_request
      expect(response.body).to include 'Conflict (An object (druid:abc123) with the source ID &#39;googlebooks:999999&#39; has already been registered.)'
    end
  end

  context 'when register is successful with controlled digital lending' do
    let(:submitted) do
      {
        registration: {

          admin_policy: 'druid:hv992ry2431',
          collection: 'druid:hv992ry7777',
          workflow_id: 'registrationWF',
          tag: ['Registered By : jcoyne85'],
          view_access: 'stanford',
          download_access: 'none',
          controlled_digital_lending: 'true',
          content_type: 'https://cocina.sul.stanford.edu/models/book',
          items: [
            {
              source_id: 'foo:bar',
              label: 'test parameters for registration'
            }
          ]
        }
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
                              identification: { sourceId: 'sul:1234' },
                              structural: {},
                              administrative: {
                                hasAdminPolicy: 'druid:hv992ry2431'
                              }).to_json
    end
    let(:request_json) do
      "{\"cocinaVersion\":\"#{Cocina::Models::VERSION}\",\"type\":\"#{Cocina::Models::ObjectType.book}\"," \
        '"label":"test parameters for registration","version":1,"access":' \
        '{"view":"stanford","download":"none","controlledDigitalLending":true},' \
        '"administrative":{"hasAdminPolicy":"druid:hv992ry2431"},"identification":' \
        '{"catalogLinks":[],"sourceId":"foo:bar"},"structural":{"contains":[],"hasMemberOrders":[],' \
        '"isMemberOf":["druid:hv992ry7777"]}}'
    end

    before do
      stub_request(:post, "#{Settings.dor_services.url}/v1/objects?assign_doi=false")
        .with(body: request_json)
        .to_return(status: 200, body: json, headers:)
    end

    it 'registers the object' do
      post '/registration', params: submitted
      expect(response).to have_http_status(:ok)
      expect(workflow_client).to have_received(:create)
        .with(version: '1')
    end
  end
end
