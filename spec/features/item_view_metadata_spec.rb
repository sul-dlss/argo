# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Item view', js: true do
  before do
    solr_conn.add(solr_doc)
    solr_conn.commit
    sign_in create(:user), groups: ['sdr:administrator-role']
    allow(Dor::Workflow::Client).to receive(:new).and_return(workflow_client)
    allow(Preservation::Client.objects).to receive(:current_version).and_return('1')
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    allow(Dor).to receive(:find).and_return(obj)
    allow(obj).to receive(:new_record?).and_return(false)
    obj.descMetadata.mods_title = 'Slides, IA 11, Geodesic Domes, Double Skin "Growth" House, N.C. State, 1953'
    allow(obj.descMetadata).to receive(:new?).and_return(false) # Must come after setting properties
    obj.contentMetadata.content = <<~XML
      <contentMetadata type="file">
        <resource type="image" sequence="126" id="hj185xx2222_126">
          <label>M1090_S15_B02_F01_0126</label>
          <file mimetype="image/jp2" preserve="yes" format="JPEG2000" size="3304904" shelve="yes" id="M1090_S15_B02_F01_0126.jp2" publish="yes">
            <imageData width="5033" height="3472"/>
            <attr name="representation">uncropped</attr>
            <checksum type="sha1">a992c8237b640b4ea413dfd3baec5e8972f53613</checksum>
            <checksum type="md5">f92f9722cb9993dd35fdea6a2219b673</checksum>
          </file>
        </resource>
      </contentMetadata>
    XML
    allow(obj.contentMetadata).to receive(:new?).and_return(false)
  end

  let(:blacklight_config) { CatalogController.blacklight_config }
  let(:solr_conn) { blacklight_config.repository_class.new(blacklight_config).connection }
  let(:obj) { Dor::Item.new(pid: item_id) }
  let(:item_id) { 'druid:hj185xx2222' }
  let(:event) { Dor::Services::Client::Events::Event.new(event_type: 'shelve_request_received', data: { 'host' => 'dor-services-stage.stanford.edu' }) }
  let(:datastream) { Dor::Services::Client::Metadata::Datastream.new(dsid: 'descMetadata', pid: item_id) }
  let(:metadata_client) { instance_double(Dor::Services::Client::Metadata, datastreams: [datastream]) }
  let(:events_client) { instance_double(Dor::Services::Client::Events, list: [event]) }
  let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, current: 1, inventory: [version1]) }
  let(:version1) { Dor::Services::Client::ObjectVersion::Version.new }
  let(:all_workflows) { instance_double(Dor::Workflow::Response::Workflows, workflows: []) }
  let(:workflow_routes) { instance_double(Dor::Workflow::Client::WorkflowRoutes, all_workflows: all_workflows) }
  let(:workflow_client) do
    instance_double(Dor::Workflow::Client,
                    active_lifecycle: [],
                    lifecycle: [],
                    milestones: {},
                    workflow_routes: workflow_routes,
                    workflow_status: nil)
  end

  context 'when there is an error retrieving the cocina_model' do
    let(:object_client) do
      instance_double(Dor::Services::Client::Object,
                      version: version_client,
                      events: events_client,
                      metadata: metadata_client)
    end
    let(:solr_doc) { { id: item_id } }

    before do
      allow(object_client).to receive(:find).and_raise(Dor::Services::Client::UnexpectedResponse)
    end

    it 'shows the page' do
      visit solr_document_path item_id
      within '.document-metadata' do
        expect(page).to have_css 'dt', text: 'DRUID:'
        expect(page).to have_css 'dd', text: item_id
      end
    end
  end

  context 'when the cocina_model exists' do
    let(:object_client) do
      instance_double(Dor::Services::Client::Object,
                      find: cocina_model,
                      version: version_client,
                      events: events_client,
                      metadata: metadata_client)
    end
    let(:attrs) do
      <<~JSON
        {
          "type": "http://cocina.sul.stanford.edu/models/image.jsonld",
          "externalIdentifier": "druid:hj185xx2222",
          "label": "image integration test miry low_explosive",
          "version": 3,
          "access": {
            "access": "world",
            "download": "world"
          },
          "administrative": {
            "hasAdminPolicy": "druid:qc410yz8746",
            "partOfProject": "Integration Test - Image via Preassembly"
          },
          "description": {
            "title": [
              {
                "value": "image integration test miry low_explosive"
              }
            ],
            "purl": "http://purl.stanford.edu/hj185xx2222",
            "access": {
              "digitalRepository": [
                {
                  "value": "Stanford Digital Repository"
                }
              ]
            }
          },
          "identification": {
            "sourceId": "image-integration-test:birken-edward_weston"
          },
          "structural": {
            "contains": [
              {
                "type": "http://cocina.sul.stanford.edu/models/resources/file.jsonld",
                "externalIdentifier": "hj185xx2222_1",
                "label": "Image 1",
                "version": 3,
                "structural": {
                  "contains": [
                    {
                      "type": "http://cocina.sul.stanford.edu/models/file.jsonld",
                      "externalIdentifier": "druid:hj185xx2222/image.jpg",
                      "label": "image.jpg",
                      "filename": "image.jpg",
                      "size": 29634,
                      "version": 3,
                      "hasMimeType": "image/jpeg",
                      "hasMessageDigests": [
                        {
                          "type": "sha1",
                          "digest": "85a32f398e228e8228ad84422941110597e0d87a"
                        },
                        {
                          "type": "md5",
                          "digest": "3e9498107f73ff827e718d5c743f8813"
                        }
                      ],
                      "access": {
                        "access": "dark",
                        "download": "none"
                      },
                      "administrative": {
                        "sdrPreserve": true,
                        "shelve": false,
                        "publish": false
                      },
                      "presentation": {
                        "height": 700,
                        "width": 500
                      }
                    },
                    {
                      "type": "http://cocina.sul.stanford.edu/models/file.jsonld",
                      "externalIdentifier": "druid:hj185xx2222/M1090_S15_B02_F01_0126.jp2",
                      "label": "M1090_S15_B02_F01_0126.jp2",
                      "filename": "M1090_S15_B02_F01_0126.jp2",
                      "size": 65738,
                      "version": 3,
                      "hasMimeType": "image/jp2",
                      "hasMessageDigests": [
                        {
                          "type": "sha1",
                          "digest": "547818142cca6bf8c888ab14644a386459fe5f92"
                        },
                        {
                          "type": "md5",
                          "digest": "45f7262c456d2ee14570881416a7432e"
                        }
                      ],
                      "access": {
                        "access": "world",
                        "download": "world"
                      },
                      "administrative": {
                        "sdrPreserve": false,
                        "shelve": true,
                        "publish": true
                      },
                      "presentation": {
                        "height": 700,
                        "width": 500
                      }
                    }
                  ]
                }
              }
            ],
            "isMemberOf": [
              "druid:bc778pm9866"
            ]
          }
        }
      JSON
    end

    let(:cocina_model) { Cocina::Models::DRO.new(JSON.parse(attrs)) }

    context 'when the file is on stacks' do
      let(:solr_doc) do
        {
          id: item_id,
          SolrDocument::FIELD_OBJECT_TYPE => 'item',
          content_type_ssim: 'image',
          status_ssi: 'v1 Unknown Status',
          SolrDocument::FIELD_APO_ID => 'info:fedora/druid:ww057qx5555',
          SolrDocument::FIELD_APO_TITLE => 'Stanford University Libraries - Special Collections',
          project_tag_ssim: 'Fuller Slides',
          source_id_ssim: 'fuller:M1090_S15_B02_F01_0126',
          identifier_tesim: ['fuller:M1090_S15_B02_F01_0126', 'uuid:ad2d8894-7eba-11e1-b714-0016034322e7'],
          tag_ssim: ['Project : Fuller Slides', 'Registered By : renzo']
        }
      end

      it 'shows the file info' do
        visit solr_document_path item_id
        within '.document-metadata' do
          expect(page).to have_css 'dt', text: 'DRUID:'
          expect(page).to have_css 'dd', text: item_id
          expect(page).to have_css 'dt', text: 'Object Type:'
          expect(page).to have_css 'dd', text: 'item'
          expect(page).to have_css 'dt', text: 'Content Type:'
          expect(page).to have_css 'dd', text: 'image'
          expect(page).to have_css 'dt', text: 'Admin Policy:'
          expect(page).to have_css 'dd a', text: 'Stanford University Libraries - Special Collections'
          expect(page).to have_css 'dt', text: 'Project:'
          expect(page).to have_css 'dd a', text: 'Fuller Slides'
          expect(page).to have_css 'dt', text: 'Source:'
          expect(page).to have_css 'dd', text: 'fuller:M1090_S15_B02_F01_0126'
          expect(page).to have_css 'dt', text: 'IDs:'
          expect(page).to have_css 'dd', text: 'fuller:M1090_S15_B02_F01_0126, uuid:ad2d8894-7eba-11e1-b714-0016034322e7'
          expect(page).to have_css 'dt', text: 'Tags:'
          expect(page).to have_css 'dd a', text: 'Project : Fuller Slides'
          expect(page).to have_css 'dd a', text: 'Registered By : renzo'
          expect(page).to have_css 'dt', text: 'Status:'
          expect(page).to have_css 'dd', text: 'v1 Unknown Status'
        end

        click_link 'descMetadata' # Open the datastream modal
        within '.code' do
          expect(page).to have_content '<title>Slides, IA 11, Geodesic Domes, Double Skin "Growth" House, N.C. State, 1953</title>'
        end
        click_button '×' # close the modal

        within '.resource-list' do
          click_link 'M1090_S15_B02_F01_0126.jp2'
        end

        within '.modal-content' do
          expect(page).to have_link 'https://stacks-test.stanford.edu/file/druid:hj185xx2222/M1090_S15_B02_F01_0126.jp2'
        end
      end
    end

    context 'when the file is on stacks' do
      let(:filename) { 'M1090_S15_B02_F01_0126.jp2' }
      let(:solr_doc) { { id: item_id } }

      before do
        page.driver.browser.download_path = '.'
      end

      after do
        File.delete(filename) if File.exist?(filename)
      end

      it 'can be downloaded' do
        visit solr_document_path item_id

        within '.resource-list' do
          click_link 'M1090_S15_B02_F01_0126.jp2'
        end
      end
    end

    context 'when the title has an ampersand in it' do
      let(:solr_doc) { { id: item_id, obj_label_tesim: 'Road & Track' } }

      let(:dro_struct) { instance_double(Cocina::Models::DROStructural, contains: []) }

      it 'properly escapes the title' do
        visit solr_document_path item_id
        expect(page).to have_title 'Road & Track'
      end
    end
  end
end
