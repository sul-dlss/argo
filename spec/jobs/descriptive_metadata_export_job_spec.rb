# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DescriptiveMetadataExportJob, type: :job do
  subject(:job) { described_class.new }

  let(:bulk_action) { create(:bulk_action, action_type: 'ExportTagsJob') }
  let(:csv_path) { File.join(bulk_action.output_directory, Settings.descriptive_metadata_export_job.csv_filename) }
  let(:log_buffer) { StringIO.new }
  let(:object_client1) { instance_double(Dor::Services::Client::Object, find: item1) }
  let(:object_client2) { instance_double(Dor::Services::Client::Object, find: item2) }

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
    let(:druids) { [druid1, druid2] }
    let(:druid1) { 'druid:bc123df4567' }
    let(:druid2) { 'druid:bd123fg5678' }
    let(:groups) { [] }
    let(:user) { instance_double(User, to_s: 'jcoyne85') }

    let(:item1) do
      Cocina::Models::Factories.build(:dro, id: 'druid:bc123df4567', source_id: 'sul:4444')
    end

    let(:item2) do
      Cocina::Models::Factories.build(:dro, id: 'druid:bd123fg5678', title: 'Test DRO #2')
    end

    context 'when happy path' do
      before do
        job.perform(bulk_action.id,
                    druids: druids,
                    groups: groups,
                    user: user)
      end

      it 'writes a CSV file' do
        csv = CSV.read(csv_path, headers: true)
        expect(csv.headers).to eq ['druid', 'source_id', 'purl', 'title1:value']
        expect(csv[0][0]).to eq 'druid:bc123df4567'
        expect(csv[1][0]).to eq 'druid:bd123fg5678'
        expect(csv[0][1]).to eq 'sul:4444'
        expect(csv[1][1]).to eq 'sul:1234'
        expect(csv[1]['title1:value']).to eq 'Test DRO #2'
      end
    end
  end
end
