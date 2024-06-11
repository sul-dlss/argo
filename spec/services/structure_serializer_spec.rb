# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StructureSerializer do
  subject(:csv) do
    described_class.as_csv(cocina.externalIdentifier, cocina.structural)
  end

  let(:cocina) do
    Cocina::Models.build(JSON.parse(json))
  end

  let(:druid) { 'druid:qr773tm1060' }
  let(:bare_druid) { 'qr773tm1060' }

  context 'with no resources' do
    let(:json) do
      <<~JSON
        {
          "type": "#{Cocina::Models::ObjectType.image}",
          "externalIdentifier": "#{druid}",
          "label": "dood",
          "version": 1,
          "access": {
            "view": "world",
            "download": "world"
          },
          "administrative": {
            "hasAdminPolicy": "druid:fh940mz2717"
          },
          "description": {
            "title": [
              {
                "value": "dood"
              }
            ],
            "purl": "https://purl.stanford.edu/qr773tm1060",
            "access": {
              "digitalRepository": [
                {
                  "value": "Stanford Digital Repository"
                }
              ]
            }
          },
          "identification": {
            "sourceId": "foo:129"
          },
          "structural": {}
        }
      JSON
    end

    it 'serializes to CSV' do
      expect(csv).to eq <<~CSV
        druid,resource_label,resource_type,sequence,filename,file_label,publish,shelve,preserve,rights_view,rights_download,rights_location,mimetype,role,file_language,sdr_generated_text,corrected_for_accessibility
      CSV
    end
  end

  context 'with multiple resources' do
    let(:json) do
      <<~JSON
        {
          "type": "#{Cocina::Models::ObjectType.image}",
          "externalIdentifier": "#{druid}",
          "label": "dood",
          "version": 1,
          "access": {
            "view": "world",
            "download": "world"
          },
          "administrative": {
            "hasAdminPolicy": "druid:fh940mz2717"
          },
          "description": {
            "title": [
              {
                "value": "dood"
              }
            ],
            "purl": "https://purl.stanford.edu/qr773tm1060",
            "access": {
              "digitalRepository": [
                {
                  "value": "Stanford Digital Repository"
                }
              ]
            }
          },
          "identification": {
            "sourceId": "foo:129"
          },
          "structural": {
            "contains": [
              {
                "type": "#{Cocina::Models::FileSetType.image}",
                "externalIdentifier": "https://cocina.sul.stanford.edu/fileSet/e43590ae-abf9-4a5c-88f2-a8627969dc23",
                "label": "Image 1",
                "version": 1,
                "structural": {
                  "contains": [
                    {
                      "type": "#{Cocina::Models::ObjectType.file}",
                      "externalIdentifier": "https://cocina.sul.stanford.edu/file/de24d694-2fe8-41a5-9113-ae6adf4506fd",
                      "label": "bb045jk9908_0001.tiff",
                      "filename": "bb045jk9908_0001.tiff",
                      "size": 22454748,
                      "version": 1,
                      "hasMimeType": "image/tiff",
                      "hasMessageDigests": [
                        {
                          "type": "sha1",
                          "digest": "ff66b3b3dc3ef733d39e949549791ff78754871b"
                        },
                        {
                          "type": "md5",
                          "digest": "b6ce12a1dd5db09f10b51659c83f90a3"
                        }
                      ],
                      "access": {
                        "view": "world",
                        "download": "world"
                      },
                      "administrative": {
                        "publish": false,
                        "sdrPreserve": true,
                        "shelve": false
                      },
                      "presentation": {
                        "height": 5833,
                        "width": 4001
                      }
                    },
                    {
                      "type": "#{Cocina::Models::ObjectType.file}",
                      "externalIdentifier": "https://cocina.sul.stanford.edu/file/92db9253-19b7-4092-b472-6e73f3c2251e",
                      "label": "bb045jk9908_0001.jp2",
                      "filename": "bb045jk9908_0001.jp2",
                      "size": 4379498,
                      "version": 1,
                      "hasMimeType": "image/jp2",
                      "hasMessageDigests": [
                        {
                          "type": "sha1",
                          "digest": "9fafbab8986cea0c70bb0aacc9ce282482cad22e"
                        },
                        {
                          "type": "md5",
                          "digest": "1633661828d894cdaa79f5549f0cd025"
                        }
                      ],
                      "access": {
                        "view": "world",
                        "download": "world"
                      },
                      "administrative": {
                        "publish": true,
                        "sdrPreserve": false,
                        "shelve": true
                      },
                      "presentation": {
                        "height": 5833,
                        "width": 4001
                      }
                    }
                  ]
                }
              },
              {
                "type": "#{Cocina::Models::FileSetType.image}",
                "externalIdentifier": "https://cocina.sul.stanford.edu/fileSet/a45774e4-ac26-425a-b40e-f5e247135843",
                "label": "Image 2",
                "version": 1,
                "structural": {
                  "contains": [
                    {
                      "type": "#{Cocina::Models::ObjectType.file}",
                      "externalIdentifier": "https://cocina.sul.stanford.edu/file/86de37bc-b930-49ac-936b-15e8db7af88e",
                      "label": "bb045jk9908_0002.tiff",
                      "filename": "bb045jk9908_0002.tiff",
                      "size": 19962338,
                      "version": 1,
                      "hasMimeType": "image/tiff",
                      "hasMessageDigests": [
                        {
                          "type": "sha1",
                          "digest": "a6a8e34aaafb8b11e5b06749ad5e7c9879b81850"
                        },
                        {
                          "type": "md5",
                          "digest": "62f0228e64728a2b28dd960910cf88bd"
                        }
                      ],
                      "access": {
                        "view": "world",
                        "download": "world"
                      },
                      "administrative": {
                        "publish": false,
                        "sdrPreserve": true,
                        "shelve": false
                      },
                      "presentation": {
                        "height": 5833,
                        "width": 4001
                      }
                    },
                    {
                      "type": "#{Cocina::Models::ObjectType.file}",
                      "externalIdentifier": "https://cocina.sul.stanford.edu/file/55d78b7f-b043-4880-8542-b85f2c3b0414",
                      "label": "bb045jk9908_0002.jp2",
                      "filename": "bb045jk9908_0002.jp2",
                      "size": 4391262,
                      "version": 1,
                      "hasMimeType": "image/jp2",
                      "use": "transcription",
                      "sdrGeneratedText": true,
                      "correctedForAccessibility": true,
                      "hasMessageDigests": [
                        {
                          "type": "sha1",
                          "digest": "5681fd7d546f436aab183e2e7ed82a15e90d71ce"
                        },
                        {
                          "type": "md5",
                          "digest": "3aaad28b903831983e6714269f10f9b1"
                        }
                      ],
                      "access": {
                        "view": "location-based",
                        "download": "location-based",
                        "location": "music"
                      },
                      "administrative": {
                        "publish": true,
                        "sdrPreserve": false,
                        "shelve": true
                      },
                      "presentation": {
                        "height": 5833,
                        "width": 4001
                      }
                    }
                  ]
                }
              }
            ]
          }
        }
      JSON
    end

    it 'serializes to CSV' do
      expect(csv).to eq <<~CSV
        druid,resource_label,resource_type,sequence,filename,file_label,publish,shelve,preserve,rights_view,rights_download,rights_location,mimetype,role,file_language,sdr_generated_text,corrected_for_accessibility
        #{bare_druid},Image 1,image,1,bb045jk9908_0001.tiff,bb045jk9908_0001.tiff,no,no,yes,world,world,,image/tiff,,,false,false
        #{bare_druid},Image 1,image,1,bb045jk9908_0001.jp2,bb045jk9908_0001.jp2,yes,yes,no,world,world,,image/jp2,,,false,false
        #{bare_druid},Image 2,image,2,bb045jk9908_0002.tiff,bb045jk9908_0002.tiff,no,no,yes,world,world,,image/tiff,,,false,false
        #{bare_druid},Image 2,image,2,bb045jk9908_0002.jp2,bb045jk9908_0002.jp2,yes,yes,no,location-based,location-based,music,image/jp2,transcription,,true,true
      CSV
    end
  end
end
