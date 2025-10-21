# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ImportStructuralJob do
  subject(:job) { described_class.new(bulk_action.id, druids: [druid], csv_file:) }

  let(:druid) { 'druid:zp968gy7494' }

  let(:file_path) { File.join(file_fixture_path, 'bulk_upload_structural.csv') }
  let(:csv_file) { CsvUploadNormalizer.read(file_path) }

  let(:bulk_action) { create(:bulk_action, action_type: 'ImportStructuralJob') }
  let(:log) { StringIO.new }
  let(:cocina_object) { build(:dro_with_metadata, id: druid).new(structural:, access: { view: 'world', download: 'world' }) }

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
                label: 'jt667tw2770_00_0001.tif',
                filename: 'jt667tw2770_00_0001.tif',
                size: 22_454_748,
                use: 'master',
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
                label: 'jt667tw2770_05_0001.jp2',
                filename: 'jt667tw2770_05_0001.jp2',
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
                  view: 'location-based',
                  download: 'location-based',
                  location: 'music'
                },
                administrative: {
                  publish: true,
                  sdrPreserve: true,
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

  let(:job_item) do
    described_class::ImportStructuralJobItem.new(druid: druid, index: 0, job: job).tap do |job_item|
      allow(job_item).to receive(:open_new_version_if_needed!)
      allow(job_item).to receive(:close_version_if_needed!)
      allow(job_item).to receive_messages(check_update_ability?: true, cocina_object: cocina_object)
    end
  end

  before do
    allow(described_class::ImportStructuralJobItem).to receive(:new).and_return(job_item)
    allow_any_instance_of(BulkAction).to receive(:open_log_file).and_return(log) # rubocop:disable RSpec/AnyInstance
    allow(Repository).to receive(:store)
  end

  it 'performs the job' do
    job.perform_now

    expect(job_item).to have_received(:check_update_ability?)
    expect(job_item).to have_received(:open_new_version_if_needed!).with(description: 'Updating content')
    expect(Repository).to have_received(:store).with(instance_of(Cocina::Models::DROWithMetadata))
    expect(job_item).to have_received(:close_version_if_needed!)

    expect(bulk_action.reload.druid_count_total).to eq 1
    expect(bulk_action.druid_count_success).to eq 1
    expect(bulk_action.druid_count_fail).to eq 0
  end

  context 'when not authorized to update' do
    before do
      allow(job_item).to receive(:check_update_ability?).and_return(false)
    end

    it 'does not update the structural' do
      job.perform_now

      expect(Repository).not_to have_received(:store)
    end
  end

  context 'when provided structural is invalid' do
    # The structure update will fail for this cocina object since it has to have matching files.
    let(:cocina_object) { build(:dro_with_metadata, id: druid) }

    it 'records a failure' do
      job.perform_now

      expect(Repository).not_to have_received(:store)

      expect(bulk_action.reload.druid_count_total).to eq 1
      expect(bulk_action.druid_count_success).to eq 0
      expect(bulk_action.druid_count_fail).to eq 1
    end
  end
end
