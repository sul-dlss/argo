# frozen_string_literal: true

require "rails_helper"

RSpec.describe RemoteIndexingJob do
  let(:bulk_action) do
    create(
      :bulk_action,
      action_type: "RemoteIndexingJob"
    )
  end

  let(:log_buffer) { StringIO.new }

  before do
    allow(subject).to receive(:bulk_action).and_return(bulk_action)
    allow(BulkJobLog).to receive(:open).and_yield(log_buffer)
  end

  describe "#perform" do
    let(:druids) { ["druid:bb111cc2222", "druid:cc111dd2222", "druid:dd111ee2222"] }
    let(:params) { {druids:} }

    context "in a happy world" do
      it "updates the total druid count, attempts to update the APO for each druid, and commits to solr" do
        druids.each do |druid|
          expect(subject).to receive(:reindex_druid_safely).with(druid, log_buffer)
        end
        subject.perform(bulk_action.id, params)
        expect(bulk_action.druid_count_total).to eq druids.length
      end

      it "logs info about progress" do
        allow(subject).to receive(:reindex_druid_safely)
        subject.perform(bulk_action.id, params)
        bulk_action_id = bulk_action.id
        expect(log_buffer.string).to include "Starting RemoteIndexingJob for BulkAction #{bulk_action_id}"
        druids.each do |druid|
          expect(log_buffer.string).to include "RemoteIndexingJob: Attempting to index #{druid} (bulk_action.id=#{bulk_action_id})"
        end
        expect(log_buffer.string).to include "Finished RemoteIndexingJob for BulkAction #{bulk_action_id}"
      end

      it "increments the failure and success counts, keeps running even if an individual update fails, and logs status of each update" do
        timeout_err = Argo::Exceptions::ReindexError.new("Timed out connecting to server")
        expect(Argo::Indexer).to receive(:reindex_druid_remotely).with(druids[0])
        expect(Argo::Indexer).to receive(:reindex_druid_remotely).with(druids[1]).and_raise(StandardError)
        expect(Argo::Indexer).to receive(:reindex_druid_remotely).with(druids[2]).and_raise(timeout_err)

        subject.perform(bulk_action.id, params)
        expect(bulk_action.druid_count_success).to eq 1
        expect(bulk_action.druid_count_fail).to eq 2

        bulk_action_id = bulk_action.id
        expect(log_buffer.string).to include "RemoteIndexingJob: Successfully reindexed #{druids[0]} (bulk_action.id=#{bulk_action_id})"
        expect(log_buffer.string).to include "RemoteIndexingJob: Unexpected error for #{druids[1]} (bulk_action.id=#{bulk_action_id}): StandardError"
        expect(log_buffer.string).to include "RemoteIndexingJob: Unexpected error for #{druids[2]} (bulk_action.id=#{bulk_action_id}): #{timeout_err}"
      end
    end
  end

  describe "#reindex_druid_safely" do
    let(:druid) { "123" }

    it "logs a success and increments the success count if reindexing works" do
      expect(Argo::Indexer).to receive(:reindex_druid_remotely).with(druid)

      subject.send(:reindex_druid_safely, druid, log_buffer)
      expect(log_buffer.string).to include "RemoteIndexingJob: Successfully reindexed #{druid} (bulk_action.id=#{bulk_action.id})"
      expect(bulk_action.druid_count_success).to eq 1
      expect(bulk_action.druid_count_fail).to eq 0
    end

    it "logs an error and increments the error count if reindexing works, but does not raise an error itself" do
      expect(Argo::Indexer).to receive(:reindex_druid_remotely).with(druid).and_raise("didn't see that one coming")

      expect { subject.send(:reindex_druid_safely, druid, log_buffer) }.not_to raise_error
      expect(log_buffer.string).to include "RemoteIndexingJob: Unexpected error for #{druid} (bulk_action.id=#{bulk_action.id}): didn't see that one coming"
      expect(bulk_action.druid_count_success).to eq 0
      expect(bulk_action.druid_count_fail).to eq 1
    end
  end
end
