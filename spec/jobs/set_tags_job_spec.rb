# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SetTagsJob, type: :job do
  let(:bulk_action) { create(:bulk_action, action_type: 'SetTagsJob') }
  let(:log_buffer) { StringIO.new }
  let(:object_client1) { instance_double(Dor::Services::Client::Object, administrative_tags: tags_client1) }
  let(:object_client2) { instance_double(Dor::Services::Client::Object, administrative_tags: tags_client2) }
  let(:tags_client1) { instance_double(Dor::Services::Client::AdministrativeTags, replace: tags1) }
  let(:tags_client2) { instance_double(Dor::Services::Client::AdministrativeTags, replace: tags2) }

  before do
    allow(subject).to receive(:bulk_action).and_return(bulk_action)
    allow(subject).to receive(:with_bulk_action_log).and_yield(log_buffer)
    allow(Dor::Services::Client).to receive(:object).with(druid1).and_return(object_client1)
    allow(Dor::Services::Client).to receive(:object).with(druid2).and_return(object_client2)
    allow(Argo::Indexer).to receive(:reindex_pid_remotely)
  end

  describe '#perform_now' do
    let(:pids) { ["druid:123\tProject : Testing 1", "druid:456\tProject : Testing 2\tTest Tag : Testing 3"] }
    let(:druid1) { 'druid:123' }
    let(:tags1) { ['Project : Testing 1'] }
    let(:druid2) { 'druid:456' }
    let(:tags2) { ['Project : Testing 2', 'Test Tag : Testing 3'] }
    let(:groups) { [] }
    let(:user) { instance_double(User, to_s: 'jcoyne85') }

    context 'happy path' do
      it 'adds tags to pids in list' do
        subject.perform(bulk_action.id,
                        pids: pids,
                        groups: groups,
                        user: user)

        expect(tags_client1).to have_received(:replace).with(tags: tags1)
        expect(tags_client2).to have_received(:replace).with(tags: tags2)
        expect(Argo::Indexer).to have_received(:reindex_pid_remotely).twice
        expect(bulk_action.druid_count_total).to eq(pids.length)
        expect(bulk_action.druid_count_success).to eq(pids.length)
        expect(bulk_action.druid_count_fail).to eq(0)
        expect(log_buffer.string).to include "SetTagsJob: Attempting to set tags for #{druid1} (bulk_action.id=#{bulk_action.id})"
        expect(log_buffer.string).to include "SetTagsJob: Attempting to set tags for #{druid2} (bulk_action.id=#{bulk_action.id})"
        expect(log_buffer.string).not_to include 'SetTagsJob: Unexpected error for'
      end
    end

    context 'AdministrativeTag::Client thrown an error' do
      before do
        allow(tags_client1).to receive(:replace).with(tags: tags1).and_raise(StandardError, 'ruh roh')
        allow(tags_client2).to receive(:replace).with(tags: tags2).and_raise(StandardError, 'ruh roh')
        allow(Rails.logger).to receive(:error)
      end

      it 'fails and records failure counts' do
        subject.perform(bulk_action.id,
                        pids: pids,
                        groups: groups,
                        user: user)

        expect(bulk_action.druid_count_total).to eq(pids.length)
        expect(bulk_action.druid_count_success).to eq(0)
        expect(bulk_action.druid_count_fail).to eq(pids.length)
        expect(log_buffer.string).to include "SetTagsJob: Unexpected error for #{druid1} (bulk_action.id=#{bulk_action.id}): ruh roh"
        expect(log_buffer.string).to include "SetTagsJob: Unexpected error for #{druid2} (bulk_action.id=#{bulk_action.id}): ruh roh"
      end
    end
  end
end
