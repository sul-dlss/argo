# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ExportStructuralJob do
  subject(:job) { described_class.new(bulk_action.id, druids: [druid]) }

  let(:druid) { 'druid:bc123df4567' }
  let(:bulk_action) { create(:bulk_action) }
  let(:csv_path) { File.join(bulk_action.output_directory, Settings.export_structural_job.csv_filename) }
  let(:log) { StringIO.new }

  let(:structural) do
    {
      contains: [
        {
          type: Cocina::Models::FileSetType.image.to_s,
          externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/e43590ae-abf9-4a5c-88f2-a8627969dc23',
          label: 'Image 1',
          version: 1,
          structural: {
            contains: [
              {
                type: Cocina::Models::ObjectType.file.to_s,
                externalIdentifier: 'https://cocina.sul.stanford.edu/file/de24d694-2fe8-41a5-9113-ae6adf4506fd',
                label: 'bb045jk9908_0001.tiff',
                filename: 'bb045jk9908_0001.tiff',
                size: 22_454_748,
                version: 1,
                hasMimeType: 'image/tiff',
                hasMessageDigests: [
                  {
                    type: 'sha1',
                    digest: 'ff66b3b3dc3ef733d39e949549791ff78754871b'
                  },
                  {
                    type: 'md5',
                    digest: 'b6ce12a1dd5db09f10b51659c83f90a3'
                  }
                ],
                access: {
                  view: 'world',
                  download: 'world'
                },
                administrative: {
                  publish: false,
                  sdrPreserve: true,
                  shelve: false
                },
                presentation: {
                  height: 5833,
                  width: 4001
                }
              },
              {
                type: Cocina::Models::ObjectType.file.to_s,
                externalIdentifier: 'https://cocina.sul.stanford.edu/file/92db9253-19b7-4092-b472-6e73f3c2251e',
                label: 'bb045jk9908_0001.jp2',
                filename: 'bb045jk9908_0001.jp2',
                size: 4_379_498,
                version: 1,
                hasMimeType: 'image/jp2',
                hasMessageDigests: [
                  {
                    type: 'sha1',
                    digest: '9fafbab8986cea0c70bb0aacc9ce282482cad22e'
                  },
                  {
                    type: 'md5',
                    digest: '1633661828d894cdaa79f5549f0cd025'
                  }
                ],
                access: {
                  view: 'world',
                  download: 'world'
                },
                administrative: {
                  publish: true,
                  sdrPreserve: false,
                  shelve: true
                },
                presentation: {
                  height: 5833,
                  width: 4001
                }
              }
            ]
          }
        },
        {
          type: Cocina::Models::FileSetType.image.to_s,
          externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/a45774e4-ac26-425a-b40e-f5e247135843',
          label: 'Image 2',
          version: 1,
          structural: {
            contains: [
              {
                type: Cocina::Models::ObjectType.file.to_s,
                externalIdentifier: 'https://cocina.sul.stanford.edu/file/86de37bc-b930-49ac-936b-15e8db7af88e',
                label: 'bb045jk9908_0002.tiff',
                filename: 'bb045jk9908_0002.tiff',
                size: 19_962_338,
                version: 1,
                hasMimeType: 'image/tiff',
                hasMessageDigests: [
                  {
                    type: 'sha1',
                    digest: 'a6a8e34aaafb8b11e5b06749ad5e7c9879b81850'
                  },
                  {
                    type: 'md5',
                    digest: '62f0228e64728a2b28dd960910cf88bd'
                  }
                ],
                access: {
                  view: 'world',
                  download: 'world'
                },
                administrative: {
                  publish: false,
                  sdrPreserve: true,
                  shelve: false
                },
                presentation: {
                  height: 5833,
                  width: 4001
                }
              },
              {
                type: Cocina::Models::ObjectType.file.to_s,
                externalIdentifier: 'https://cocina.sul.stanford.edu/file/55d78b7f-b043-4880-8542-b85f2c3b0414',
                label: 'bb045jk9908_0002.jp2',
                filename: 'bb045jk9908_0002.jp2',
                size: 4_391_262,
                version: 1,
                hasMimeType: 'image/jp2',
                hasMessageDigests: [
                  {
                    type: 'sha1',
                    digest: '5681fd7d546f436aab183e2e7ed82a15e90d71ce'
                  },
                  {
                    type: 'md5',
                    digest: '3aaad28b903831983e6714269f10f9b1'
                  }
                ],
                access: {
                  view: 'world',
                  download: 'world'
                },
                administrative: {
                  publish: true,
                  sdrPreserve: false,
                  shelve: true
                },
                presentation: {
                  height: 5833,
                  width: 4001
                }
              }
            ]
          }
        }
      ]
    }
  end

  let(:cocina_object) do
    build(:dro, id: druid).new(structural:, access: { view: 'world', download: 'world' })
  end

  let(:job_item) do
    described_class::ExportStructuralJobItem.new(druid: druid, index: 0, job: job).tap do |job_item|
      allow(job_item).to receive(:cocina_object).and_return(cocina_object)
    end
  end

  before do
    allow(described_class::ExportStructuralJobItem).to receive(:new).and_return(job_item)
    allow_any_instance_of(BulkAction).to receive(:open_log_file).and_return(log) # rubocop:disable RSpec/AnyInstance
  end

  after do
    FileUtils.rm_f(csv_path)
  end

  it 'performs the job' do
    job.perform_now

    expect(described_class::ExportStructuralJobItem).to have_received(:new).with(druid:, index: 0, job:)

    expect(bulk_action.reload.druid_count_total).to eq(1)
    expect(bulk_action.druid_count_success).to eq(1)
    expect(bulk_action.druid_count_fail).to eq(0)

    expect(log.string).to include "Exported structural metadata for #{druid}"

    expect(File).to exist(csv_path)
    output = CSV.read(csv_path, headers: true)
    expect(output.size).to eq 4 # header + 2 filesets + 2 files
    expect(output.first.to_csv).to eq "bc123df4567,Image 1,image,1,bb045jk9908_0001.tiff,bb045jk9908_0001.tiff,no,no,yes,world,world,,image/tiff,,,false,false\n"
  end

  context 'when no structural metadata is present' do
    let(:cocina_object) { build(:dro, id: druid) }

    it 'records a failure' do
      job.perform_now

      expect(bulk_action.reload.druid_count_fail).to eq(1)
      expect(log.string).to include "No structural metadata to export for #{druid}"

      expect(File).to exist(csv_path)
      File.open(csv_path, 'r') do |file|
        expect(file.readlines.size).to eq 1 # just a header row
      end
    end
  end
end
