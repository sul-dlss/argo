# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RemoteIndexingJob do
  let(:bulk_action) do
    create(
      :bulk_action,
      action_type: 'RemoteIndexingJob'
    )
  end

  let(:log) { StringIO.new }

  let(:object_client) { instance_double(Dor::Services::Client::Object, reindex: true) }

  before do
    allow(subject).to receive(:bulk_action).and_return(bulk_action)
    allow_any_instance_of(BulkAction).to receive(:open_log_file).and_return(log) # rubocop:disable RSpec/AnyInstance
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
  end

  describe '#perform' do
    let(:druids) { ['druid:bb111cc2222', 'druid:cc111dd2222', 'druid:dd111ee2222'] }
    let(:params) { { druids: } }

    context 'when happy path' do
      it 'updates the total druid count, attempts to update the APO for each druid, and commits to solr' do
        subject.perform(bulk_action.id, params)
        expect(bulk_action.druid_count_total).to eq druids.length
        expect(object_client).to have_received(:reindex).exactly(druids.length).times
      end

      it 'logs info about progress' do
        subject.perform(bulk_action.id, params)
        expect(log.string).to include "Starting RemoteIndexingJob for BulkAction #{bulk_action.id}"
        druids.each do |druid|
          expect(log.string).to include "Reindex successful for #{druid}"
        end
        expect(log.string).to include "Finished RemoteIndexingJob for BulkAction #{bulk_action.id}"
      end
    end

    context 'when there are errors with individual druids' do
      let(:object_client_standarderror) { instance_double(Dor::Services::Client::Object) }
      let(:object_client_timeout) { instance_double(Dor::Services::Client::Object) }

      before do
        allow(Dor::Services::Client).to receive(:object).with(druids[0]).and_return(object_client)
        allow(Dor::Services::Client).to receive(:object).with(druids[1]).and_return(object_client_standarderror)
        allow(Dor::Services::Client).to receive(:object).with(druids[2]).and_return(object_client_timeout)

        allow(object_client_standarderror).to receive(:reindex).and_raise(StandardError)
        allow(object_client_timeout).to receive(:reindex).and_raise(Argo::Exceptions::ReindexError.new('Timed out connecting to server'))
      end

      it 'increments the failure and success counts, keeps running even if an individual update fails, and logs status of each update' do
        subject.perform(bulk_action.id, params)
        expect(bulk_action.druid_count_success).to eq 1
        expect(bulk_action.druid_count_fail).to eq 2

        expect(log.string).to include "Reindex successful for #{druids[0]}"
        expect(log.string).to include "Failed StandardError StandardError for #{druids[1]}"
        expect(log.string).to include "Failed Argo::Exceptions::ReindexError Timed out connecting to server for #{druids[2]}"
      end
    end
  end
end
