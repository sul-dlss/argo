# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Item view', :js do
  before do
    sign_in create(:user), groups: ['sdr:administrator-role']
  end

  let(:blacklight_config) { CatalogController.blacklight_config }
  let(:solr_conn) { blacklight_config.repository_class.new(blacklight_config).connection }
  let(:item_id) { 'druid:hj185xx2222' }
  let(:props) { {} }
  let(:event) do
    Dor::Services::Client::Events::Event.new(
      event_type: 'shelve_request_received',
      data: {
        host: 'dor-services-stage.stanford.edu',
        **props
      }
    )
  end
  let(:events_client) { instance_double(Dor::Services::Client::Events, list: [event]) }
  let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, current: 1, inventory: [version1]) }
  let(:version1) { Dor::Services::Client::ObjectVersion::Version.new }
  let(:all_workflows) { instance_double(Dor::Workflow::Response::Workflows, workflows: []) }
  let(:workflow_routes) { instance_double(Dor::Workflow::Client::WorkflowRoutes, all_workflows:) }
  let(:workflow_client) do
    instance_double(Dor::Workflow::Client,
                    active_lifecycle: [],
                    lifecycle: [],
                    milestones: {},
                    workflow_routes:,
                    workflow_status: nil)
  end

  context 'when navigating to an object' do
    before do
      solr_conn.add(solr_doc)
      solr_conn.commit
    end

    context 'when displaying the catalog view' do
      let(:solr_doc) do
        {
          id: 'druid:hj185xx2222',
          objectType_ssim: 'item',
          display_title_ss: title
        }
      end
      let(:title) { 'Slides, IA 11, Geodesic Domes, Double Skin "Growth" House, N.C. State, 1953' }

      it 'shows the catalog index view' do
        visit search_catalog_path f: { objectType_ssim: ['item'] }
        expect(page).to have_css '.index_title a', text: title
      end
    end

    context 'when viewing the object' do
      before do
        allow(Dor::Workflow::Client).to receive(:new).and_return(workflow_client)
        allow(Preservation::Client.objects).to receive(:current_version).and_return('1')
        allow(Dor::Services::Client).to receive(:object).and_return(object_client)
      end

      context 'when there is an error retrieving the cocina_model' do
        let(:solr_doc) { { :id => item_id, SolrDocument::FIELD_OBJECT_TYPE => 'item' } }
        let(:object_client) do
          instance_double(Dor::Services::Client::Object,
                          version: version_client,
                          events: events_client)
        end

        before do
          allow(object_client).to receive(:find_lite).and_raise(Dor::Services::Client::UnexpectedResponse.new(response: ''))
        end

        it 'shows the page' do
          visit solr_document_path item_id
          expect(page).to have_content 'Warning: this object cannot currently be represented in the Cocina model.'
        end
      end

      context 'when the cocina_model exists' do
        let(:object_client) do
          instance_double(Dor::Services::Client::Object,
                          find_lite: cocina_object_lite,
                          find: cocina_object,
                          version: version_client,
                          events: events_client)
        end
        let(:cocina_object_lite) { Cocina::Models::DROLite.new(props) }
        let(:cocina_object) do
          cocina_object = Cocina::Models::DRO.new(props)
          Cocina::Models.with_metadata(cocina_object, 'abc123')
        end

        let(:props) do
          {
            type: Cocina::Models::ObjectType.image.to_s,
            externalIdentifier: 'druid:hj185xx2222',
            label: 'image integration test miry low_explosive',
            version: 3,
            access: {
              view: 'world',
              download: 'world'
            },
            administrative: {
              hasAdminPolicy: 'druid:qc410yz8746',
              releaseTags: [
                {
                  release: true,
                  what: 'self',
                  to: 'Searchworks',
                  who: 'pjreed',
                  date: '2017-10-20T15:42:15Z'
                }
              ]
            },
            description: {
              title: [
                {
                  value: 'image integration test miry low_explosive'
                }
              ],
              purl: 'https://purl.stanford.edu/hj185xx2222',
              access: {
                digitalRepository: [
                  {
                    value: 'Stanford Digital Repository'
                  }
                ]
              }
            },
            identification: {
              sourceId: 'image-integration-test:birken-edward_weston'
            },
            structural: {
              contains: [
                {
                  type: Cocina::Models::FileSetType.file.to_s,
                  externalIdentifier: 'hj185xx2222_1',
                  label: 'Image 1',
                  version: 3,
                  structural: {
                    contains: [
                      {
                        type: Cocina::Models::ObjectType.file.to_s,
                        externalIdentifier: 'druid:hj185xx2222/image.jpg',
                        label: 'image.jpg',
                        filename: 'image.jpg',
                        size: 29_634,
                        version: 3,
                        hasMimeType: 'image/jpeg',
                        hasMessageDigests: [
                          {
                            type: 'sha1',
                            digest: '85a32f398e228e8228ad84422941110597e0d87a'
                          },
                          {
                            type: 'md5',
                            digest: '3e9498107f73ff827e718d5c743f8813'
                          }
                        ],
                        access: {
                          view: 'dark',
                          download: 'none'
                        },
                        administrative: {
                          sdrPreserve: true,
                          shelve: false,
                          publish: false
                        },
                        presentation: {
                          height: 700,
                          width: 500
                        }
                      },
                      {
                        type: Cocina::Models::ObjectType.file.to_s,
                        externalIdentifier: 'druid:hj185xx2222/M1090_S15_B02_F01_0126.jp2',
                        label: 'M1090_S15_B02_F01_0126.jp2',
                        filename: 'M1090_S15_B02_F01_0126.jp2',
                        size: 65_738,
                        version: 3,
                        hasMimeType: 'image/jp2',
                        hasMessageDigests: [
                          {
                            type: 'sha1',
                            digest: '547818142cca6bf8c888ab14644a386459fe5f92'
                          },
                          {
                            type: 'md5',
                            digest: '45f7262c456d2ee14570881416a7432e'
                          }
                        ],
                        access: {
                          view: 'world',
                          download: 'world'
                        },
                        administrative: {
                          sdrPreserve: false,
                          shelve: true,
                          publish: true
                        },
                        presentation: {
                          height: 700,
                          width: 500
                        }
                      }
                    ]
                  }
                }
              ],
              isMemberOf: [
                'druid:bc778pm9866'
              ]
            }
          }
        end

        context 'when the file is on stacks' do
          let(:solr_doc) do
            {
              :id => item_id,
              SolrDocument::FIELD_OBJECT_TYPE => 'item',
              :content_type_ssim => 'image',
              :status_ssi => 'v1 Unknown Status',
              :rights_descriptions_ssim => %w[world dark],
              SolrDocument::FIELD_APO_ID => 'info:fedora/druid:ww057qx5555',
              SolrDocument::FIELD_APO_TITLE => 'Stanford University Libraries - Special Collections',
              :project_tag_ssim => 'Fuller Slides',
              :source_id_ssi => 'fuller:M1090_S15_B02_F01_0126',
              :identifier_tesim => ['fuller:M1090_S15_B02_F01_0126', 'uuid:ad2d8894-7eba-11e1-b714-0016034322e7'],
              :tag_ssim => ['Project : Fuller Slides', 'Registered By : renzo']
            }
          end

          it 'shows the file info' do
            visit solr_document_path item_id

            within_table('Overview') do
              expect(page).to have_css 'th', text: 'DRUID'
              expect(page).to have_css 'td', text: item_id
              expect(page).to have_css 'th', text: 'Admin policy'
              expect(page).to have_css 'td a', text: 'Stanford University Libraries - Special Collections'
              expect(page).to have_css 'th', text: 'Status'
              expect(page).to have_css 'th', text: 'Access rights'
              expect(page).to have_css 'td', text: 'View: World, Download: World'
              expect(page).to have_css 'td', text: 'v1 Unknown Status'
            end

            within_table('Details') do
              expect(page).to have_css 'th', text: 'Object type'
              expect(page).to have_css 'td', text: 'item'
              expect(page).to have_css 'th', text: 'Content type'
              expect(page).to have_css 'td', text: 'image'
              expect(page).to have_css 'th', text: 'Project'
              expect(page).to have_css 'td a', text: 'Fuller Slides'
              expect(page).to have_css 'th', text: 'Source IDs'
              expect(page).to have_css 'td', text: 'fuller:M1090_S15_B02_F01_0126'
              expect(page).to have_css 'th', text: 'Tags'
              expect(page).to have_css 'td a', text: 'Project : Fuller Slides'
              expect(page).to have_css 'td a', text: 'Registered By : renzo'
            end

            # Release History
            expect(page).to have_css 'dt', text: 'Releases'
            expect(page).to have_css 'table.table thead tr th', text: 'Release'
            expect(page).to have_css 'tr td', text: /Searchworks/
            expect(page).to have_css 'tr td', text: /pjreed/

            # The following three clicks make sure events are expandable and collapsible
            click_button 'Events'
            # NOTE: Without scrolling to the events section, the clicks below were flappy. (example RSpec seed: 39192)
            scroll_to find_by_id('document-events-heading')
            within '#events' do
              click_button 'View more'
              click_button 'View less'
            end

            expect(page).to have_text 'View content in folder hierarchy'

            within '.resource-list' do
              click_link 'M1090_S15_B02_F01_0126.jp2'
            end

            within '#blacklight-modal' do
              expect(page).to have_link 'https://stacks-test.stanford.edu/file/druid:hj185xx2222/M1090_S15_B02_F01_0126.jp2'
            end
          end
        end

        context 'when the title has an ampersand in it' do
          let(:solr_doc) do
            { :id => item_id, SolrDocument::FIELD_TITLE => 'Road & Track', SolrDocument::FIELD_OBJECT_TYPE => 'item' }
          end

          let(:dro_struct) { instance_double(Cocina::Models::DROStructural, contains: []) }

          it 'properly escapes the title' do
            visit solr_document_path item_id
            expect(page).to have_title 'Road & Track'
          end
        end
      end
    end
  end

  context 'for an adminPolicy' do
    let(:cocina_model) { instance_double(Cocina::Models::AdminPolicyWithMetadata, administrative:, as_json: {}) }
    let(:administrative) { instance_double(Cocina::Models::AdminPolicyAdministrative) }
    let(:id) { 'druid:qv778ht9999' }

    before do
      solr_conn.add(id:)
      solr_conn.commit
    end

    it 'does not show release history' do
      visit solr_document_path id
      expect(page).to have_no_css 'dt', text: 'Releases'
    end
  end
end
