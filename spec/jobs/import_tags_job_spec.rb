# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ImportTagsJob do
  subject(:job) { described_class.new(bulk_action.id, csv_file:) }

  let(:druid) { 'druid:bc123df4567' }

  let(:bulk_action) { create(:bulk_action) }
  let(:log) { StringIO.new }
  let(:object_client) { instance_double(Dor::Services::Client::Object, administrative_tags: tags_client) }
  # let(:object_client2) { instance_double(Dor::Services::Client::Object, administrative_tags: tags_client2, reindex: true) }
  # let(:tags_client1) { instance_double(Dor::Services::Client::AdministrativeTags, list: tags, destroy: true) }
  # let(:tags_client2) { instance_double(Dor::Services::Client::AdministrativeTags, replace: true) }

  before do
    # allow(job).to receive(:bulk_action).and_return(bulk_action)
    allow_any_instance_of(BulkAction).to receive(:open_log_file).and_return(log) # rubocop:disable RSpec/AnyInstance
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
    # allow(Dor::Services::Client).to receive(:object).with(druid2).and_return(object_client2)
  end

  context 'when replacing tags' do
    let(:csv_file) { "#{druid},Tag : One,Tag : Two\n" }

    let(:tags_client) { instance_double(Dor::Services::Client::AdministrativeTags, replace: true) }

    it 'performs the job' do
      job.perform_now

      expect(tags_client).to have_received(:replace).with(tags: ['Tag : One', 'Tag : Two'])

      expect(log.string).to include "Replaced tags (Tag : One, Tag : Two) for #{druid}"

      expect(bulk_action.reload.druid_count_total).to eq(1)
      expect(bulk_action.druid_count_success).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(0)
    end
  end

  context 'when destroying all tags' do
    let(:csv_file) { "#{druid}\n" }

    let(:tag) { 'Existing Tag' }
    let(:tags_client) { instance_double(Dor::Services::Client::AdministrativeTags, list: [tag], destroy: true) }

    it 'performs the job' do
      job.perform_now

      expect(tags_client).to have_received(:list).once
      expect(tags_client).to have_received(:destroy).with(tag:).once

      expect(log.string).to include "Destroyed all tags for #{druid}"

      expect(bulk_action.reload.druid_count_total).to eq(1)
      expect(bulk_action.druid_count_success).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(0)
    end
  end
end
