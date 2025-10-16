# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SetCollectionJob do
  subject(:job) { described_class.new(bulk_action.id, druids: [druid], new_collection_id: collection_id) }

  let(:druid) { 'druid:bb111cc2222' }
  let(:bulk_action) { create(:bulk_action) }

  let(:collection_id) { 'druid:bc111bb2222' }

  let(:job_item) do
    described_class::SetCollectionJobItem.new(druid: druid, index: 0, job: job).tap do |job_item|
      allow(job_item).to receive(:open_new_version_if_needed!)
      allow(job_item).to receive(:close_version_if_needed!)
      allow(job_item).to receive_messages(check_update_ability?: true, cocina_object: cocina_object)
    end
  end

  let(:cocina_object) { instance_double(Cocina::Models::DRO) }
  let(:change_set) { instance_double(ItemChangeSet, validate: true, save: true) }

  before do
    allow(described_class::SetCollectionJobItem).to receive(:new).and_return(job_item)
    allow(ItemChangeSet).to receive(:new).and_return(change_set)
  end

  after do
    FileUtils.rm_rf(bulk_action.output_directory)
  end

  context 'when changing the collection' do
    it 'performs the job' do
      job.perform_now

      expect(job_item).to have_received(:check_update_ability?)
      expect(job_item).to have_received(:open_new_version_if_needed!).with(description: 'Added to collections druid:bc111bb2222.')
      expect(ItemChangeSet).to have_received(:new).with(cocina_object)
      expect(change_set).to have_received(:validate).with(collection_ids: [collection_id])
      expect(change_set).to have_received(:save)
      expect(job_item).to have_received(:close_version_if_needed!)

      expect(bulk_action.reload.druid_count_total).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(0)
      expect(bulk_action.druid_count_success).to eq(1)
    end
  end

  context 'when removing from collection' do
    let(:collection_id) { '' }

    it 'performs the job' do
      job.perform_now

      expect(job_item).to have_received(:open_new_version_if_needed!).with(description: 'Removed collection membership.')
      expect(change_set).to have_received(:validate).with(collection_ids: [])

      expect(bulk_action.reload.druid_count_success).to eq(1)
    end
  end

  context 'when not authorized to update' do
    before do
      allow(job_item).to receive(:check_update_ability?).and_return(false)
    end

    it 'does not change the collection' do
      job.perform_now

      expect(ItemChangeSet).not_to have_received(:new)
    end
  end
end
