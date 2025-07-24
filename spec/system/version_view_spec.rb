# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Version view', :js do
  let(:blacklight_config) { CatalogController.blacklight_config }
  let(:solr_conn) { blacklight_config.repository_class.new(blacklight_config).connection }
  let(:druid) { 'druid:hj185xx2222' }
  let(:version_client) do
    instance_double(Dor::Services::Client::ObjectVersion,
                    current: 1,
                    inventory: [version1, version2],
                    find: cocina_object, solr: solr_doc)
  end
  let(:user_version_client) { instance_double(Dor::Services::Client::UserVersion, inventory: [user_version1]) }
  let(:release_tags_client) { instance_double(Dor::Services::Client::ReleaseTags, list: release_tags_list) }
  let(:version1) { Dor::Services::Client::ObjectVersion::Version.new(versionId: 1, message: 'Initial version', cocina: false) }
  let(:version2) { Dor::Services::Client::ObjectVersion::Version.new(versionId: 2, message: 'Changed version', cocina: true) }
  let(:user_version1) { Dor::Services::Client::UserVersion::Version.new(version: 4, userVersion: 2, withdrawable: false, restorable: false) }

  let(:release_tags_list) do
    [
      Dor::Services::Client::ReleaseTag.new(to: 'Searchworks', what: 'self', date: '2016-09-12T20:00Z', who: 'pjreed',
                                            release: false),
      Dor::Services::Client::ReleaseTag.new(to: 'Searchworks', what: 'self', date: '2016-09-13T20:00Z', who: 'pjreed',
                                            release: true)
    ]
  end
  let(:version_service) { instance_double(VersionService, open?: true, openable?: false, open_and_not_assembling?: true, closeable?: true) }

  before do
    sign_in create(:user), groups: ['sdr:administrator-role']

    allow(Preservation::Client.objects).to receive(:current_version).and_return('1')
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    allow(VersionService).to receive(:new).and_return(version_service)
    allow(MilestoneService).to receive(:milestones_for).and_return({})
    allow(WorkflowService).to receive_messages(workflows_for: [], accessioned?: true)
  end

  context 'when viewing the object' do
    let(:object_client) do
      instance_double(Dor::Services::Client::Object,
                      find_lite: cocina_object_lite,
                      version: version_client,
                      user_version: user_version_client,
                      release_tags: release_tags_client)
    end
    let(:cocina_object_lite) { Cocina::Models::DROLite.new(cocina_props) }
    let(:cocina_object) do
      cocina_object = Cocina::Models::DRO.new(cocina_props)
      Cocina::Models.with_metadata(cocina_object, 'abc123')
    end

    let(:cocina_props) do
      {
        type: Cocina::Models::ObjectType.image.to_s,
        externalIdentifier: 'druid:hj185xx2222',
        label: title,
        version: 3,
        access: {
          view: 'world',
          download: 'world'
        },
        administrative: {
          hasAdminPolicy: 'druid:qc410yz8746'
        },
        description: {
          title: [
            {
              value: title
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

    let(:title) { 'image integration test miry low_explosive' }

    let(:solr_doc) do
      {
        :id => druid,
        SolrDocument::FIELD_TITLE => title,
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

    context 'when viewing the version' do
      it 'shows the current version' do
        visit item_version_path(item_id: druid, version_id: 2)

        expect(page).to have_content(title)
        expect(page).to have_content('You are viewing the latest version.')
        expect(page).to have_no_content('View latest version')
        expect(page).to have_no_content('Technical metadata')
        # And nothing should be editable
        expect(page).to have_no_css('.bi-pencil')
        expect(page).to have_content('Older versions are not released')
        expect(page).to have_no_css('.open-close') # Lock icon
        expect(page).to have_no_link('Withdraw')
        expect(page).to have_no_link('Restore')
        expect(page).to have_text('image.jpg')
        expect(page).to have_no_link('image.jpg')

        expect(version_client).to have_received(:find).with('2').at_least(:once)
        expect(version_client).to have_received(:solr).with('2')
      end
    end

    context 'when viewing an older version' do
      it 'shows the older system version banner' do
        visit item_version_path(item_id: druid, version_id: 1)

        expect(page).to have_content(title)
        expect(page).to have_content('You are viewing an older system version.')
        expect(page).to have_link('View latest version', href: "/view/#{druid}")
        expect(page).to have_no_content('Technical metadata')
        # And nothing should be editable
        expect(page).to have_no_css('.bi-pencil')
        expect(page).to have_content('Older versions are not released')
        expect(page).to have_no_css('.open-close') # Lock icon
        expect(page).to have_no_link('Withdraw')
        expect(page).to have_no_link('Restore')
        expect(page).to have_text('image.jpg')
        expect(page).to have_no_link('image.jpg')

        expect(version_client).to have_received(:find).with('1').at_least(:once)
        expect(version_client).to have_received(:solr).with('1')
      end
    end

    context 'when viewing an unknown version' do
      before do
        allow(version_client).to receive(:find).and_raise(Dor::Services::Client::NotFoundResponse)
      end

      it 'shows a 404' do
        visit item_version_path(item_id: druid, version_id: 4)

        expect(page).to have_content('The page you were looking for doesn’t exist.')
      end
    end
  end
end
