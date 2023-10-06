# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ExportTagsJob do
  subject(:job) { described_class.new }

  let(:bulk_action) { create(:bulk_action, action_type: 'ExportTagsJob') }
  let(:csv_path) { File.join(bulk_action.output_directory, Settings.export_tags_job.csv_filename) }
  let(:log_buffer) { StringIO.new }
  let(:object_client1) { instance_double(Dor::Services::Client::Object, administrative_tags: tags_client1) }
  let(:object_client2) { instance_double(Dor::Services::Client::Object, administrative_tags: tags_client2) }
  let(:tags_client1) { instance_double(Dor::Services::Client::AdministrativeTags, list: tags1) }
  let(:tags_client2) { instance_double(Dor::Services::Client::AdministrativeTags, list: tags2) }

  before do
    allow(job).to receive(:bulk_action).and_return(bulk_action)
    allow(BulkJobLog).to receive(:open).and_yield(log_buffer)
    allow(Dor::Services::Client).to receive(:object).with(druid1).and_return(object_client1)
    allow(Dor::Services::Client).to receive(:object).with(druid2).and_return(object_client2)
  end

  after do
    FileUtils.rm_f(csv_path)
  end

  describe '#perform_now' do
    let(:druids) { [druid1, druid2] }
    let(:druid1) { 'druid:bc123df4567' }
    let(:tags1) { ['Project : Testing 1'] }
    let(:druid2) { 'druid:bd123fg5678' }
    let(:tags2) { ['Project : Testing 2', 'Test Tag : Testing 3'] }
    let(:groups) { [] }
    let(:user) { instance_double(User, to_s: 'jcoyne85') }

    context 'when happy path' do
      before do
        job.perform(bulk_action.id,
                    druids:,
                    groups:,
                    user:)
      end

      it 'collaborates with the tags client for each druid' do
        expect(tags_client1).to have_received(:list).once
        expect(tags_client2).to have_received(:list).once
      end

      it 'records zero failures and all successes' do
        expect(bulk_action.druid_count_total).to eq(druids.length)
        expect(bulk_action.druid_count_success).to eq(druids.length)
        expect(bulk_action.druid_count_fail).to eq(0)
      end

      it 'logs messages for each druid in the list' do
        expect(log_buffer.string).to include "Exporting tags for #{druid1} (bulk_action.id=#{bulk_action.id})"
        expect(log_buffer.string).to include "Exporting tags for #{druid2} (bulk_action.id=#{bulk_action.id})"
        expect(log_buffer.string).not_to include 'Unexpected error'
      end

      it 'writes a CSV file' do
        expect(File).to exist(csv_path)
      end
    end

    context 'when an exception is raised' do
      before do
        allow(tags_client1).to receive(:list).and_raise(StandardError, 'ruh roh')
        allow(tags_client2).to receive(:list).and_raise(StandardError, 'ruh roh')
        job.perform(bulk_action.id,
                    druids:,
                    groups:,
                    user:)
      end

      it 'collaborates with the tags client for each druid' do
        expect(tags_client1).to have_received(:list).once
        expect(tags_client2).to have_received(:list).once
      end

      it 'records all failures and zero successes' do
        expect(bulk_action.druid_count_total).to eq(druids.length)
        expect(bulk_action.druid_count_success).to eq(0)
        expect(bulk_action.druid_count_fail).to eq(druids.length)
      end

      it 'logs messages for each druid in the list' do
        expect(log_buffer.string).to include "Unexpected error exporting tags for #{druid1} (bulk_action.id=#{bulk_action.id}): ruh roh"
        expect(log_buffer.string).to include "Unexpected error exporting tags for #{druid2} (bulk_action.id=#{bulk_action.id}): ruh roh"
      end

      it 'writes an empty CSV file' do
        expect(File).to exist(csv_path)
        expect(File.empty?(csv_path)).to be true
      end
    end
  end
end
