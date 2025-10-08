# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ExportCocinaJsonJob do
  subject(:job) { described_class.new }

  let(:bulk_action) { create(:bulk_action, action_type: 'ExportCocinaJsonJob') }
  let(:jsonl_path) { File.join(bulk_action.output_directory, Settings.export_cocina_json_job.jsonl_filename) }
  let(:gzip_path) { File.join(bulk_action.output_directory, Settings.export_cocina_json_job.gzip_filename) }
  let(:unzipped_path) { File.join(bulk_action.output_directory, 'unzipped_file.jsonl') }
  let(:log) { StringIO.new }
  let(:groups) { [] }
  let(:user) { instance_double(User, to_s: 'jcoyne85') }
  let(:druids) { [druid1, druid2, druid3] }
  let(:druid1) { 'druid:bc123df4567' }
  let(:druid2) { 'druid:bd123fg5678' }
  let(:druid3) { 'druid:bf123fg5678' }
  let(:object_client1) { instance_double(Dor::Services::Client::Object, find: obj1) }
  let(:object_client2) { instance_double(Dor::Services::Client::Object, find: obj2) }
  let(:object_client3) { instance_double(Dor::Services::Client::Object, find: obj3) }
  let(:obj1) { build(:dro_with_metadata, id: druid1) }
  let(:obj2) { build(:dro_with_metadata, id: druid2) }
  let(:obj3) { build(:dro_with_metadata, id: druid2) }

  before do
    allow(job).to receive(:bulk_action).and_return(bulk_action)
    allow_any_instance_of(BulkAction).to receive(:open_log_file).and_return(log) # rubocop:disable RSpec/AnyInstance
    allow(Dor::Services::Client).to receive(:object).with(druid1).and_return(object_client1)
    allow(Dor::Services::Client).to receive(:object).with(druid2).and_return(object_client2)
    allow(Dor::Services::Client).to receive(:object).with(druid3).and_return(object_client3)
  end

  after do
    FileUtils.rm_f(jsonl_path)
    FileUtils.rm_f(gzip_path)
    FileUtils.rm_f(unzipped_path)
  end

  context 'with a set of druids' do
    before do
      job.perform(bulk_action.id,
                  druids:,
                  groups:,
                  user:)
    end

    after do
      FileUtils.rm_f(jsonl_path)
      FileUtils.rm_f(gzip_path)
      FileUtils.rm_f(unzipped_path)
    end

    it 'has removed the jsonl file' do
      expect(File).not_to exist(jsonl_path)
    end

    it 'writes a gzip file' do
      expect(File).to exist(gzip_path)
      File.write(unzipped_path, ActiveSupport::Gzip.decompress(File.read(gzip_path)))
      expect(File.open(unzipped_path).readlines.size).to eq 3
    end

    it 'tracks success/failure' do
      expect(bulk_action.druid_count_success).to eq 3
      expect(bulk_action.druid_count_fail).to eq 0
      expect(bulk_action.druid_count_total).to eq 3
    end
  end

  context 'with an unexpected error' do
    before do
      allow(Dor::Services::Client).to receive(:object).with(druid1).and_raise(StandardError,
                                                                              'Some unexpected problem occurred.')
      job.perform(bulk_action.id,
                  druids:,
                  groups:,
                  user:)
    end

    it 'has removed the jsonl file' do
      expect(File).not_to exist(jsonl_path)
    end

    it 'writes a gzip file' do
      expect(File).to exist(gzip_path)
      File.write(unzipped_path, ActiveSupport::Gzip.decompress(File.read(gzip_path)))
      expect(File.open(unzipped_path).readlines.size).to eq 2
    end

    it 'tracks success/failure' do
      expect(bulk_action.druid_count_success).to eq 2
      expect(bulk_action.druid_count_fail).to eq 1
      expect(bulk_action.druid_count_total).to eq 3
    end

    it 'logs error for druid not found' do
      expect(log.string).to include 'Some unexpected problem occurred.'
    end
  end
end
