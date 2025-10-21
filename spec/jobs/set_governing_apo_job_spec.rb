# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SetGoverningApoJob do
  subject(:job) { described_class.new(bulk_action.id, druids: [druid], new_apo_id:) }

  let(:druid) { 'druid:bb111cc2222' }
  let(:new_apo_id) { 'druid:bc111bb2222' }
  let(:cocina_object) { instance_double(Cocina::Models::DROWithMetadata) }

  let(:bulk_action) { create(:bulk_action) }

  let(:job_item) do
    described_class::SetGoverningApoJobItem.new(druid: druid, index: 0, job: job).tap do |job_item|
      allow(job_item).to receive(:open_new_version_if_needed!)
      allow(job_item).to receive(:close_version_if_needed!)
      allow(job_item).to receive(:cocina_object).and_return(cocina_object)
    end
  end

  let(:log) { StringIO.new }
  let(:change_set) { instance_double(ItemChangeSet, validate: true, save: true) }
  let(:ability) { instance_double(Ability, can?: true) }

  before do
    allow_any_instance_of(BulkAction).to receive(:open_log_file).and_return(log) # rubocop:disable RSpec/AnyInstance
    allow(described_class::SetGoverningApoJobItem).to receive(:new).and_return(job_item)
    allow(ItemChangeSet).to receive(:new).and_return(change_set)
    allow(job).to receive(:ability).and_return(ability)
  end

  it 'performs the job' do
    job.perform_now

    expect(ability).to have_received(:can?).with(:manage_governing_apo, cocina_object, new_apo_id)
    expect(job_item).to have_received(:open_new_version_if_needed!)
    expect(ItemChangeSet).to have_received(:new).with(cocina_object)
    expect(change_set).to have_received(:validate).with(admin_policy_id: new_apo_id)
    expect(change_set).to have_received(:save)

    expect(job_item).to have_received(:close_version_if_needed!)

    expect(bulk_action.reload.druid_count_total).to eq(1)
    expect(bulk_action.druid_count_fail).to eq(0)
    expect(bulk_action.druid_count_success).to eq(1)
  end

  context 'when the user lacks manage ability' do
    before do
      allow(ability).to receive(:can?).and_return(false)
    end

    it 'does not update the governing APO' do
      job.perform_now

      expect(ItemChangeSet).not_to have_received(:new)

      expect(bulk_action.reload.druid_count_total).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(1)
      expect(bulk_action.druid_count_success).to eq(0)
    end
  end
end
