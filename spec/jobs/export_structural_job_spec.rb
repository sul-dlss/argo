# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ExportStructuralJob, type: :job do
  subject(:job) { described_class.new }

  let(:bulk_action) { create(:bulk_action, action_type: 'ExportStructuralJob') }
  let(:csv_path) { File.join(bulk_action.output_directory, Settings.export_structural_job.csv_filename) }
  let(:log_buffer) { StringIO.new }
  let(:object_client1) { instance_double(Dor::Services::Client::Object, find: obj1) }
  let(:object_client2) { instance_double(Dor::Services::Client::Object, find: obj2) }
  let(:json1) do
    <<~JSON
      {
        "type": "#{Cocina::Models::ObjectType.image}",
        "externalIdentifier": "druid:bc123df4567",
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
          "purl": "https://purl.stanford.edu/bc123df4567",
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
  let(:obj1) do
    Cocina::Models.build(JSON.parse(json1))
  end
  let(:json2) do
    <<~JSON
      {
        "type": "#{Cocina::Models::ObjectType.image}",
        "externalIdentifier": "druid:bd123fg5678",
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
          "purl": "https://purl.stanford.edu/bd123fg5678",
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
  let(:obj2) do
    Cocina::Models.build(JSON.parse(json2))
  end

  before do
    allow(job).to receive(:bulk_action).and_return(bulk_action)
    allow(job).to receive(:with_bulk_action_log).and_yield(log_buffer)
    allow(Dor::Services::Client).to receive(:object).with(druid1).and_return(object_client1)
    allow(Dor::Services::Client).to receive(:object).with(druid2).and_return(object_client2)
  end

  after do
    FileUtils.rm_f(csv_path)
  end

  describe '#perform_now' do
    let(:pids) { [druid1, druid2] }
    let(:druid1) { 'druid:bc123df4567' }
    let(:druid2) { 'druid:bd123fg5678' }
    let(:groups) { [] }
    let(:user) { instance_double(User, to_s: 'jcoyne85') }

    context 'when happy path' do
      before do
        job.perform(bulk_action.id,
                    pids: pids,
                    groups: groups,
                    user: user)
      end

      it 'logs messages and creates a file' do
        expect(bulk_action.druid_count_total).to eq pids.length
        expect(bulk_action.druid_count_success).to eq pids.length
        expect(bulk_action.druid_count_fail).to be_zero
        expect(log_buffer.string).to include "Exporting structural metadata for #{druid1}"
        expect(log_buffer.string).to include "Exporting structural metadata for #{druid2}"
        expect(File).to exist(csv_path)
        File.open(csv_path, 'r') do |file|
          expect(file.readlines.size).to eq 9 # one row for each file plus the headers.
        end
      end
    end

    context 'when an exception is raised' do
      before do
        allow(object_client1).to receive(:find).and_raise(StandardError, 'ruh roh')
        allow(object_client2).to receive(:find).and_raise(StandardError, 'ruh roh')
        job.perform(bulk_action.id,
                    pids: pids,
                    groups: groups,
                    user: user)
      end

      it 'records all failures and creates an empty file' do
        expect(bulk_action.druid_count_total).to eq pids.length
        expect(bulk_action.druid_count_success).to be_zero
        expect(bulk_action.druid_count_fail).to eq pids.length
        expect(log_buffer.string).to include "Unexpected error exporting structural metadata for #{druid1}: ruh roh"
        expect(log_buffer.string).to include "Unexpected error exporting structural metadata for #{druid2}: ruh roh"
        expect(File).to exist(csv_path)
        File.open(csv_path, 'r') do |file|
          expect(file.readlines.size).to eq 1 # just a header row
        end
      end
    end

    context 'when an no structural metadata is present' do
      let(:json1) do
        <<~JSON
          {
            "type": "#{Cocina::Models::ObjectType.collection}",
            "externalIdentifier": "druid:bc123df4567",
            "label": "dood",
            "version": 1,
            "access": {
              "view": "world"
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
              "purl": "https://purl.stanford.edu/bc123df4567"
            },
            "identification": {
              "sourceId": "foo:129"
            }
          }
        JSON
      end
      let(:json2) do
        <<~JSON
          {
            "type": "#{Cocina::Models::ObjectType.image}",
            "externalIdentifier": "druid:bd123fg5678",
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
              "purl": "https://purl.stanford.edu/bd123fg5678"
            },
            "identification": {
              "sourceId": "foo:129"
            },
            "structural": {
              "contains": []
            }
          }
        JSON
      end

      before do
        job.perform(bulk_action.id,
                    pids: pids,
                    groups: groups,
                    user: user)
      end

      it 'records all failures and creates an empty file' do
        expect(bulk_action.druid_count_total).to eq pids.length
        expect(bulk_action.druid_count_success).to be_zero
        expect(bulk_action.druid_count_fail).to eq pids.length
        expect(log_buffer.string).to include 'Object druid:bc123df4567 has no structural metadata to export'
        expect(log_buffer.string).to include 'Object druid:bd123fg5678 has no structural metadata to export'
        expect(File).to exist(csv_path)
        File.open(csv_path, 'r') do |file|
          expect(file.readlines.size).to eq 1 # just a header row
        end
      end
    end
  end
end
