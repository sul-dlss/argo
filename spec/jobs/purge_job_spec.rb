# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PurgeJob do
  subject(:job) { described_class.new(bulk_action.id, druids: [druid]) }

  let(:druid) { 'druid:bb111cc2222' }
  let(:bulk_action) { create(:bulk_action) }

  let(:job_item) do
    described_class::PurgeJobItem.new(druid: druid, index: 0, job: job).tap do |job_item|
      allow(job_item).to receive(:check_update_ability?).and_return(true)
    end
  end

  before do
    allow(described_class::PurgeJobItem).to receive(:new).and_return(job_item)
    allow(WorkflowService).to receive(:submitted?).and_return(false)
    allow(PurgeService).to receive(:purge)
  end

  after do
    FileUtils.rm(bulk_action.log_name)
  end

  it 'performs the job' do
    job.perform_now

    expect(job_item).to have_received(:check_update_ability?)
    expect(WorkflowService).to have_received(:submitted?).with(druid: druid)
    expect(PurgeService).to have_received(:purge).with(druid: druid, user_name: bulk_action.user.to_s)

    expect(bulk_action.reload.druid_count_total).to eq(1)
    expect(bulk_action.druid_count_fail).to eq(0)
    expect(bulk_action.druid_count_success).to eq(1)
  end

  context 'when already submitted' do
    before do
      allow(WorkflowService).to receive(:submitted?).and_return(true)
    end

    it 'does not purge the object' do
      job.perform_now

      expect(PurgeService).not_to have_received(:purge)

      expect(bulk_action.reload.druid_count_total).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(1)
      expect(bulk_action.druid_count_success).to eq(0)
    end
  end

  context 'when the user lacks update ability' do
    before do
      allow(job_item).to receive(:check_update_ability?).and_return(false)
    end

    it 'does not purge the object' do
      job.perform_now

      expect(WorkflowService).not_to have_received(:submitted?)
      expect(PurgeService).not_to have_received(:purge)
    end
  end
end
