# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'catalog/_contents_default.html.erb', type: :view do
  context 'with files' do
    let(:content_md) do
      Dor::ContentMetadataDS.new.tap do |cm|
        cm.content = <<~XML
          <contentMetadata objectId="bb000zn0114" type="image">
            <resource id="bb000zn0114_1" sequence="1" type="image">
              <label>Image 1</label>
              <file id="PC0062_2008-194_Q03_02_007.jpg" preserve="yes" publish="no" shelve="no" mimetype="image/jpeg" size="1480110">
                <checksum type="md5">8e656c63ea1ad476e515518a46824fac</checksum>
                <checksum type="sha1">0cd3613c7dda558433ad955f0cf4f2730e3ec958</checksum>
                <imageData width="2548" height="1696"/>
              </file>
              <file id="PC0062_2008-194_Q03_02_007.jp2" mimetype="image/jp2" size="819813" preserve="no" publish="yes" shelve="yes">
                <checksum type="md5">1f8d562f4f1fd87946a437176bb8e564</checksum>
                <checksum type="sha1">3206db5137c0820ede261488e08f4d4815d16078</checksum>
                <imageData width="2548" height="1696"/>
              </file>
            </resource>
          </contentMetadata>
        XML
      end
    end
    let(:object) do
      instance_double(Dor::Item,
                      contentMetadata: content_md,
                      to_param: 'druid:bb000zn0114',
                      datastreams: { 'contentMetadata' => content_md })
    end
    let(:solr_doc) do
      SolrDocument.new(id: 'druid:bb000zn0114')
    end

    let(:attrs) do
      <<~JSON
        {
          "type": "http://cocina.sul.stanford.edu/models/image.jsonld",
          "externalIdentifier": "druid:bg954kx8787",
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
            "purl": "http://purl.stanford.edu/bg954kx8787",
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
                "externalIdentifier": "bg954kx8787_1",
                "label": "Image 1",
                "version": 3,
                "structural": {
                  "contains": [
                    {
                      "type": "http://cocina.sul.stanford.edu/models/file.jsonld",
                      "externalIdentifier": "druid:bg954kx8787/image.jpg",
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
                      "externalIdentifier": "druid:bg954kx8787/image.jp2",
                      "label": "image.jp2",
                      "filename": "image.jp2",
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

    before do
      @cocina = Cocina::Models::DRO.new(JSON.parse(attrs))
      allow(view).to receive(:can?).and_return(true)
      allow(content_md).to receive(:new?).and_return(false)
    end

    it 'shows multiple external files' do
      render 'catalog/contents_default', object: object, document: solr_doc
      expect(rendered).to have_link('image.jpg', href: '/items/druid:bg954kx8787/files?id=image.jpg')
      expect(rendered).to have_link('image.jp2', href: '/items/druid:bg954kx8787/files?id=image.jp2')
    end
  end
end
