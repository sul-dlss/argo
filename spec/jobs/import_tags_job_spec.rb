# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ImportTagsJob do
  subject(:job) { described_class.new }

  let(:bulk_action) { create(:bulk_action, action_type: 'ImportTagsJob') }
  let(:log_buffer) { StringIO.new }
  let(:object_client1) { instance_double(Dor::Services::Client::Object, administrative_tags: tags_client1, reindex: true) }
  let(:object_client2) { instance_double(Dor::Services::Client::Object, administrative_tags: tags_client2, reindex: true) }
  let(:tags_client1) { instance_double(Dor::Services::Client::AdministrativeTags, list: tags1, destroy: true) }
  let(:tags_client2) { instance_double(Dor::Services::Client::AdministrativeTags, replace: true) }

  before do
    allow(job).to receive(:bulk_action).and_return(bulk_action)
    allow(BulkJobLog).to receive(:open).and_yield(log_buffer)
    allow(Dor::Services::Client).to receive(:object).with(druid1).and_return(object_client1)
    allow(Dor::Services::Client).to receive(:object).with(druid2).and_return(object_client2)
  end

  describe '#perform_now' do
    let(:csv_string) { "druid:bc123df4567\n\ndruid:bc234fg7890,Tag : One,Tag : Two" }
    let(:druid1) { 'druid:bc123df4567' }
    let(:tags1) { ['First : Tag'] }
    let(:druid2) { 'druid:bc234fg7890' }
    let(:tags2) { ['Tag : One', 'Tag : Two'] }

    context 'when happy path' do
      before do
        job.perform(bulk_action.id, csv_file: csv_string)
      end

      it 'collaborates with the tags client for each druid' do
        expect(tags_client1).to have_received(:list).once
        expect(tags_client1).to have_received(:destroy).once
        expect(tags_client2).to have_received(:replace).with(tags: tags2).once
      end

      it 'records zero failures and all successes' do
        expect(bulk_action.druid_count_total).to eq(2)
        expect(bulk_action.druid_count_success).to eq(2)
        expect(bulk_action.druid_count_fail).to eq(0)
      end

      it 'logs messages for each druid in the list' do
        expect(log_buffer.string).to include "Importing tags for #{druid1} (bulk_action.id=#{bulk_action.id})"
        expect(log_buffer.string).to include "Importing tags for #{druid2} (bulk_action.id=#{bulk_action.id})"
        expect(log_buffer.string).not_to include 'ExportTagsJob: Unexpected error for'
      end

      it 'invokes the indexer for each object touched' do
        expect(object_client1).to have_received(:reindex)
        expect(object_client2).to have_received(:reindex)
      end
    end

    context 'when client throws an error' do
      before do
        allow(tags_client1).to receive(:list).and_raise(StandardError, 'ruh roh')
        allow(tags_client2).to receive(:replace).with(tags: tags2).and_raise(StandardError, 'ruh roh')
        job.perform(bulk_action.id, csv_file: csv_string)
      end

      it 'collaborates with the tags client for each druid' do
        expect(tags_client1).to have_received(:list).once
        expect(tags_client1).not_to have_received(:destroy)
        expect(tags_client2).to have_received(:replace).with(tags: tags2).once
      end

      it 'records all failures and zero successes' do
        expect(bulk_action.druid_count_total).to eq(2)
        expect(bulk_action.druid_count_success).to eq(0)
        expect(bulk_action.druid_count_fail).to eq(2)
      end

      it 'logs messages for each druid in the list' do
        expect(log_buffer.string).to include "Unexpected error importing tags for #{druid1} (bulk_action.id=#{bulk_action.id}): ruh roh"
        expect(log_buffer.string).to include "Unexpected error importing tags for #{druid2} (bulk_action.id=#{bulk_action.id}): ruh roh"
      end

      it 'fails to invoke the indexer' do
        expect(object_client1).not_to have_received(:reindex)
        expect(object_client2).not_to have_received(:reindex)
      end
    end
  end
end
