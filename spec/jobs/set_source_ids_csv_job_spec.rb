# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SetSourceIdsCsvJob do
  subject(:job) { described_class.new(bulk_action.id, csv_file:) }

  let(:bulk_action) { create(:bulk_action) }
  let(:druid) { 'druid:bb111cc2222' }
  let(:source_id) { 'sul:36105014757517' }

  let(:change_set) { instance_double(ItemChangeSet, validate: true, changed?: true, save: true) }
  let(:cocina_object) { instance_double(Cocina::Models::DROWithMetadata, collection?: false) }
  let(:log) { StringIO.new }

  let(:csv_file) do
    [
      'druid,source_id',
      [druid, source_id].join(',')
    ].join("\n")
  end

  let(:row) { CSV.parse(csv_file, headers: true).first }

  let(:job_item) do
    described_class::SetSourceIdsCsvJobItem.new(druid: druid, index: 2, job: job, row:).tap do |job_item|
      allow(job_item).to receive(:open_new_version_if_needed!)
      allow(job_item).to receive(:close_version_if_needed!)
      allow(job_item).to receive_messages(check_update_ability?: true, cocina_object: cocina_object)
    end
  end

  before do
    allow(described_class::SetSourceIdsCsvJobItem).to receive(:new).and_return(job_item)
    allow_any_instance_of(BulkAction).to receive(:open_log_file).and_return(log) # rubocop:disable RSpec/AnyInstance
    allow(ItemChangeSet).to receive(:new).and_return(change_set)
  end

  it 'performs the job' do
    job.perform_now

    expect(job_item).to have_received(:check_update_ability?)
    expect(job_item).to have_received(:open_new_version_if_needed!).with(description: 'Updated source ID')
    expect(ItemChangeSet).to have_received(:new).with(cocina_object).twice
    expect(change_set).to have_received(:validate).with(source_id:).twice
    expect(change_set).to have_received(:save)
    expect(job_item).to have_received(:close_version_if_needed!)

    expect(bulk_action.reload.druid_count_total).to eq 1
    expect(bulk_action.druid_count_success).to eq 1
    expect(bulk_action.druid_count_fail).to eq 0
  end

  context 'when there are validation errors' do
    before do
      allow(change_set).to receive(:validate).and_return(false)
      allow(change_set).to receive_message_chain(:errors, :full_messages).and_return(['Source ID is invalid']) # rubocop:disable RSpec/MessageChain
    end

    it 'records a failure' do
      job.perform_now

      expect(bulk_action.reload.druid_count_total).to eq 1
      expect(bulk_action.druid_count_success).to eq 0
      expect(bulk_action.druid_count_fail).to eq 1

      expect(log.string).to include 'Source ID is invalid'
    end
  end

  context 'when no changes' do
    before do
      allow(change_set).to receive(:changed?).and_return(false)
    end

    it 'records a success with no changes' do
      job.perform_now

      expect(bulk_action.reload.druid_count_total).to eq 1
      expect(bulk_action.druid_count_success).to eq 1
      expect(bulk_action.druid_count_fail).to eq 0

      expect(log.string).to include 'No changes to source ID'
    end
  end

  context 'when a collection' do
    let(:change_set) { instance_double(CollectionChangeSet, validate: true, changed?: true, save: true) }
    let(:cocina_object) { instance_double(Cocina::Models::CollectionWithMetadata, collection?: true) }

    before do
      allow(CollectionChangeSet).to receive(:new).and_return(change_set)
    end

    it 'performs the job' do
      job.perform_now

      expect(CollectionChangeSet).to have_received(:new).with(cocina_object).twice
      expect(change_set).to have_received(:validate).with(source_id:).twice
      expect(change_set).to have_received(:save)
    end
  end

  context 'when not authorized to update' do
    before do
      allow(job_item).to receive(:check_update_ability?).and_return(false)
    end

    it 'does not set source ID' do
      job.perform_now

      expect(ItemChangeSet).not_to have_received(:new)
    end
  end
end
