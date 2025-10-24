# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CloseVersionJob do
  subject(:job) { described_class.new(bulk_action.id, druids: [druid]) }

  let(:druid) { 'druid:bc123df4567' }
  let(:bulk_action) { create(:bulk_action) }

  let(:job_item) do
    described_class::CloseVersionJobItem.new(druid: druid, index: 0, job: job).tap do |job_item|
      allow(job_item).to receive(:close_version_if_needed!)
      allow(job_item).to receive(:check_update_ability?).and_return(true)
    end
  end

  before do
    allow(described_class::CloseVersionJobItem).to receive(:new).and_return(job_item)
  end

  after do
    FileUtils.rm(bulk_action.log_name)
  end

  it 'performs the job' do
    job.perform_now

    expect(job_item).to have_received(:check_update_ability?)
    expect(job_item).to have_received(:close_version_if_needed!).with(force: true)

    expect(bulk_action.reload.druid_count_total).to eq(1)
    expect(bulk_action.druid_count_fail).to eq(0)
    expect(bulk_action.druid_count_success).to eq(1)
  end

  context 'when not authorized to update' do
    before do
      allow(job_item).to receive(:check_update_ability?).and_return(false)
    end

    it 'does not close the version' do
      job.perform_now

      expect(job_item).not_to have_received(:close_version_if_needed!)
    end
  end
end
