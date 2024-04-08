# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SetSourceIdsCsvJob do
  subject(:job) { described_class.new }

  let(:bulk_action) { create(:bulk_action, action_type: 'SetSourceIdsCsvJob') }
  let(:druids) { %w[druid:bb111cc2222 druid:cc111dd2222 druid:dd111ff2222] }

  let(:source_ids) do
    [
      'sul:36105014757517', # a basic change on an item
      '', # an invalid change on an item
      'sul:36105014757518' # an initial set on a collection
    ]
  end
  let(:log_buffer) { StringIO.new }
  let(:item1) do
    build(:dro_with_metadata, id: druids[0], source_id: 'sul:36105014757519')
  end
  let(:item2) do
    build(:dro_with_metadata, id: druids[1], source_id: 'sul:36105014757510')
  end
  let(:item3) do
    build(:collection_with_metadata, id: druids[2], source_id: 'sul:1234')
  end

  let(:csv_file) do
    [
      'druid,source_id',
      [druids[0], source_ids[0]].join(','),
      [druids[1], source_ids[1]].join(','),
      [druids[2], source_ids[2]].join(',')
    ].join("\n")
  end

  let(:object_client1) { instance_double(Dor::Services::Client::Object, find: item1, update: true) }
  let(:object_client2) { instance_double(Dor::Services::Client::Object, find: item2, update: true) }
  let(:object_client3) { instance_double(Dor::Services::Client::Object, find: item3, update: true) }

  before do
    allow(subject).to receive(:bulk_action).and_return(bulk_action)
    allow(BulkJobLog).to receive(:open).and_yield(log_buffer)
    allow(Ability).to receive(:new).and_return(ability)
    allow(VersionService).to receive(:open?).and_return(true)
    allow(Dor::Services::Client).to receive(:object).with(druids[0]).and_return(object_client1)
    allow(Dor::Services::Client).to receive(:object).with(druids[1]).and_return(object_client2)
    allow(Dor::Services::Client).to receive(:object).with(druids[2]).and_return(object_client3)
  end

  describe '#perform' do
    let(:groups) { [] }
    let(:user) { instance_double(User, to_s: 'jcoyne85') }

    context 'with manage ability' do
      let(:ability) { instance_double(Ability, can?: true) }

      context 'when the version is open' do
        before do
          job.perform(bulk_action.id,
                      csv_file:,
                      groups:,
                      user:)
        end

        it 'logs messages and creates a file' do
          expect(log_buffer.string).to include "Beginning set source_id for #{druids[0]}"
          expect(log_buffer.string).to include "Source can't be blank"
          expect(log_buffer.string).to include "Beginning set source_id for #{druids[2]}"

          expect(bulk_action.druid_count_total).to eq druids.length
          expect(bulk_action.druid_count_success).to eq 2
          expect(bulk_action.druid_count_fail).to eq 1
        end
      end

      context 'when the version is closed' do
        before do
          allow(VersionService).to receive(:open?).and_return(false)
          allow(job).to receive(:open_new_version).and_return(item1.new(version: 2), item2.new(version: 2),
                                                              item3.new(version: 2))
          job.perform(bulk_action.id,
                      csv_file:,
                      groups:,
                      user:)
        end

        it 'logs messages and creates a file' do
          expect(log_buffer.string).to include "Beginning set source_id for #{druids[0]}"
          expect(log_buffer.string).to include "Source can't be blank"
          expect(log_buffer.string).to include "Beginning set source_id for #{druids[2]}"

          expect(bulk_action.druid_count_total).to eq druids.length
          expect(bulk_action.druid_count_success).to eq 2
          expect(bulk_action.druid_count_fail).to eq 1
        end
      end

      context 'when an exception is raised' do
        before do
          allow(object_client1).to receive(:find).and_raise(StandardError, 'ruh roh')
          allow(object_client2).to receive(:find).and_raise(StandardError, 'ruh roh')
          allow(object_client3).to receive(:find).and_raise(StandardError, 'ruh roh')
          job.perform(bulk_action.id,
                      csv_file:,
                      groups:,
                      user:)
        end

        it 'records all failures and creates an empty file' do
          expect(bulk_action.druid_count_total).to eq druids.length
          expect(bulk_action.druid_count_success).to be_zero
          expect(bulk_action.druid_count_fail).to eq druids.length
          expect(log_buffer.string).to include "Unexpected error setting source_id for #{druids[0]}: ruh roh"
          expect(log_buffer.string).to include "Unexpected error setting source_id for #{druids[1]}: ruh roh"
        end
      end
    end

    context 'without manage ability' do
      let(:ability) { instance_double(Ability, can?: false) }

      before do
        job.perform(bulk_action.id,
                    csv_file:,
                    groups:,
                    user:)
      end

      it 'records all failures and creates an empty file' do
        expect(bulk_action.druid_count_total).to eq druids.length
        expect(bulk_action.druid_count_success).to be_zero
        expect(bulk_action.druid_count_fail).to eq druids.length
        expect(log_buffer.string).to include "Not authorized for #{druids[0]}"
        expect(log_buffer.string).to include "Not authorized for #{druids[1]}"
      end
    end
  end
end
