# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StructureUpdater do
  subject(:result) do
    described_class.from_csv(cocina, csv)
  end

  let(:druid) { 'druid:qr773tm1060' }
  let(:bare_druid) { 'qr773tm1060' }

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
          "purl": "https://purl.stanford.edu/#{bare_druid}",
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
            }
          ]
        }
      }
    JSON
  end

  let(:cocina) do
    Cocina::Models.build(JSON.parse(json))
  end

  context 'with valid csv that has file properties changed' do
    let(:csv) do
      <<~CSV
        druid,resource_label,resource_type,sequence,filename,file_label,publish,shelve,preserve,rights_view,rights_download,rights_location,mimetype,role
        #{bare_druid},Image 1,image,1,bb045jk9908_0001.tiff,bb045jk9908_0001.tiff,yes,yes,yes,stanford,stanford,,image/one,
        #{bare_druid},Image 1,image,1,bb045jk9908_0001.jp2,bb045jk9908_0001.jp2,yes,yes,no,world,world,,image/two,transcription
        #{bare_druid},Image 2,image,2,bb045jk9908_0002.tiff,bb045jk9908_0002.tiff,yes,yes,yes,stanford,none,,image/three,
        #{bare_druid},Image 2,image,2,bb045jk9908_0002.jp2,bb045jk9908_0002.jp2,yes,yes,no,location-based,location-based,music,image/four,
      CSV
    end

    it 'updates the files' do
      new_files = result.value!.contains.flat_map do |fileset|
        fileset.structural.contains
      end
      new_file_routing = new_files.map { |file| [file.administrative.publish, file.administrative.shelve, file.administrative.sdrPreserve] }
      expect(new_file_routing).to eq [
        [true, true, true],
        [true, true, false],
        [true, true, true],
        [true, true, false]
      ]

      new_file_mime = new_files.map(&:hasMimeType)
      expect(new_file_mime).to eq ['image/one', 'image/two', 'image/three', 'image/four']

      access = new_files.map { |file| [file.access.view, file.access.download, file.access.location] }
      expect(access).to eq [
        ['stanford', 'stanford', nil], ['world', 'world', nil], ['stanford', 'none', nil], %w[location-based location-based music]
      ]

      use = new_files.map(&:use)
      expect(use).to eq [nil, 'transcription', nil, nil]
    end

    it 'produces valid cocina' do
      expect { cocina.new(structural: result.value!) }.not_to raise_error
    end
  end

  context 'with valid csv that has fileset properties changed' do
    let(:csv) do
      <<~CSV
        druid,resource_label,resource_type,sequence,filename,file_label,publish,shelve,preserve,rights_view,rights_download,rights_location,mimetype,role
        #{bare_druid},Picture 1,object,1,bb045jk9908_0001.tiff,bb045jk9908_0001.tiff,yes,yes,yes,stanford,stanford,,image/tiff,
        #{bare_druid},Picture 1,object,1,bb045jk9908_0001.jp2,bb045jk9908_0001.jp2,yes,yes,no,world,world,,image/jp2,
        #{bare_druid},Picture 2,page,2,bb045jk9908_0002.tiff,bb045jk9908_0002.tiff,yes,yes,yes,stanford,stanford,,image/tiff,
        #{bare_druid},Picture 2,page,2,bb045jk9908_0002.jp2,bb045jk9908_0002.jp2,yes,yes,no,world,world,,image/jp2,
      CSV
    end

    it 'updates the fileset' do
      new_filesets = result.value!.contains
      expect(new_filesets.map(&:type)).to eq [
        Cocina::Models::FileSetType.object,
        Cocina::Models::FileSetType.page
      ]

      expect(new_filesets.map(&:label)).to eq [
        'Picture 1',
        'Picture 2'
      ]
    end

    it 'produces valid cocina' do
      expect { cocina.new(structural: result.value!) }.not_to raise_error
    end
  end

  context 'with valid csv that adds filesets' do
    let(:csv) do
      <<~CSV
        druid,resource_label,resource_type,sequence,filename,file_label,publish,shelve,preserve,rights_view,rights_download,rights_location,mimetype,role
        #{bare_druid},Picture 1,object,1,bb045jk9908_0001.tiff,bb045jk9908_0001.tiff,yes,yes,yes,stanford,stanford,,image/tiff,
        #{bare_druid},Picture 2,object,2,bb045jk9908_0001.jp2,bb045jk9908_0001.jp2,yes,yes,no,world,world,,image/jp2,
        #{bare_druid},Picture 3,page,3,bb045jk9908_0002.tiff,bb045jk9908_0002.tiff,yes,yes,yes,stanford,stanford,,image/tiff,
        #{bare_druid},Picture 4,page,4,bb045jk9908_0002.jp2,bb045jk9908_0002.jp2,yes,yes,no,world,world,,image/jp2,
      CSV
    end

    it 'adds the filesets' do
      new_filesets = result.value!.contains
      expect(new_filesets.map(&:label)).to eq [
        'Picture 1',
        'Picture 2',
        'Picture 3',
        'Picture 4'
      ]
    end

    it 'produces valid cocina' do
      expect { cocina.new(structural: result.value!) }.not_to raise_error
    end
  end

  context 'with valid csv that combines filesets' do
    let(:csv) do
      <<~CSV
        druid,resource_label,resource_type,sequence,filename,file_label,publish,shelve,preserve,rights_view,rights_download,rights_location,mimetype,role
        #{bare_druid},Picture 1,object,1,bb045jk9908_0001.tiff,bb045jk9908_0001.tiff,yes,yes,yes,stanford,stanford,,image/tiff,
        #{bare_druid},Picture 1,object,1,bb045jk9908_0001.jp2,bb045jk9908_0001.jp2,yes,yes,no,world,world,,image/jp2,
        #{bare_druid},Picture 1,page,1,bb045jk9908_0002.tiff,bb045jk9908_0002.tiff,yes,yes,yes,stanford,stanford,,image/tiff,
        #{bare_druid},Picture 1,page,1,bb045jk9908_0002.jp2,bb045jk9908_0002.jp2,yes,yes,no,world,world,,image/jp2,
      CSV
    end

    it 'combines the filesets' do
      new_filesets = result.value!.contains
      expect(new_filesets.map(&:label)).to eq ['Picture 1']
    end

    it 'produces valid cocina' do
      expect { cocina.new(structural: result.value!) }.not_to raise_error
    end
  end

  context 'with invalid csv' do
    let(:csv) do
      <<~CSV
        druid,resource_label,resource_type,sequence,filename,file_label,publish,shelve,preserve,rights_view,rights_download,rights_location,mimetype,role
        #{bare_druid},Image 1,image,1,bb045jk_0001.tiff,bb045jk9908_0001.tiff,yes,yes,yes,world,world,,image/tiff,
        #{bare_druid},Image 1,image,1,bb045jk_0001.jp2,bb045jk9908_0001.jp2,yes,yes,yes,world,world,,image/jp2,
        #{bare_druid},Image 2,image,2,bb045jk_0002.tiff,bb045jk9908_0002.tiff,yes,yes,yes,world,world,,image/tiff,
        #{bare_druid},Image 2,paper,2,bb045jk_0002.jp2,bb045jk9908_0002.jp2,yes,yes,yes,world,world,,image/jp2,
      CSV
    end

    it 'returns errors' do
      expect(result.failure).to eq [
        'On row 2 found bb045jk_0001.tiff, which appears to be a new file',
        'On row 3 found bb045jk_0001.jp2, which appears to be a new file',
        'On row 4 found bb045jk_0002.tiff, which appears to be a new file',
        'On row 5 found "paper", which is not a valid resource type',
        'On row 5 found bb045jk_0002.jp2, which appears to be a new file'
      ]
    end
  end

  context 'with switching preservation from no to yes for a file in the csv' do
    let(:csv) do
      <<~CSV
        druid,resource_label,resource_type,sequence,filename,file_label,publish,shelve,preserve,rights_view,rights_download,rights_location,mimetype,role
        #{bare_druid},Picture 1,object,1,bb045jk9908_0001.tiff,bb045jk9908_0001.tiff,yes,yes,yes,stanford,none,,image/tiff,
        #{bare_druid},Picture 1,object,1,bb045jk9908_0001.jp2,bb045jk9908_0001.jp2,yes,yes,no,world,world,,image/jp2,
        #{bare_druid},Picture 2,page,2,bb045jk9908_0002.tiff,bb045jk9908_0002.tiff,yes,yes,yes,stanford,none,,image/tiff,
        #{bare_druid},Picture 2,page,2,bb045jk9908_0002.jp2,bb045jk9908_0002.jp2,yes,yes,yes,world,world,,image/jp2,
      CSV
    end

    it 'returns errors' do
      expect(result.failure).to eq [
        'On row 5 found bb045jk9908_0002.jp2, which changed preserve from no to yes, which is not supported'
      ]
    end
  end

  context 'with specify location-based rights and no location' do
    let(:csv) do
      <<~CSV
        druid,resource_label,resource_type,sequence,filename,file_label,publish,shelve,preserve,rights_view,rights_download,rights_location,mimetype,role
        #{bare_druid},Picture 1,object,1,bb045jk9908_0001.tiff,bb045jk9908_0001.tiff,yes,yes,yes,stanford,none,,image/tiff,
        #{bare_druid},Picture 1,object,1,bb045jk9908_0001.jp2,bb045jk9908_0001.jp2,yes,yes,no,world,world,,image/jp2,
        #{bare_druid},Picture 2,page,2,bb045jk9908_0002.tiff,bb045jk9908_0002.tiff,yes,yes,yes,stanford,none,,image/tiff,
        #{bare_druid},Picture 2,page,2,bb045jk9908_0002.jp2,bb045jk9908_0002.jp2,yes,yes,no,location-based,world,,image/jp2,
      CSV
    end

    it 'returns errors' do
      expect(result.failure).to eq [
        'On row 5 found bb045jk9908_0002.jp2, which set view or download rights to location-based but did not specify a location'
      ]
    end
  end
end
