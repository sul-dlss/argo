# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OpenVersionJob do
  subject(:job) { described_class.new(bulk_action.id, druids: [druid], version_description:) }

  let(:druid) { 'druid:bb111cc2222' }
  let(:version_description) { 'New version' }
  let(:bulk_action) { create(:bulk_action) }

  let(:job_item) do
    described_class::OpenVersionJobItem.new(druid: druid, index: 0, job: job).tap do |job_item|
      allow(job_item).to receive(:check_update_ability?).and_return(true)
    end
  end

  before do
    allow(described_class::OpenVersionJobItem).to receive(:new).and_return(job_item)

    allow(VersionService).to receive(:open)
    allow(VersionService).to receive(:openable?).and_return(true)
  end

  it 'performs the job' do
    job.perform_now

    expect(job_item).to have_received(:check_update_ability?)
    expect(VersionService).to have_received(:openable?).with(druid: druid)
    expect(VersionService).to have_received(:open).with(druid:,
                                                        description: version_description,
                                                        opening_user_name: bulk_action.user.to_s)

    expect(bulk_action.reload.druid_count_total).to eq(1)
    expect(bulk_action.druid_count_fail).to eq(0)
    expect(bulk_action.druid_count_success).to eq(1)
  end

  context 'when not openable' do
    before do
      allow(VersionService).to receive(:openable?).and_return(false)
    end

    it 'does not open the version' do
      job.perform_now

      expect(VersionService).to have_received(:openable?).with(druid: druid)
      expect(VersionService).not_to have_received(:open)

      expect(bulk_action.reload.druid_count_total).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(1)
      expect(bulk_action.druid_count_success).to eq(0)
    end
  end

  context 'when the user lacks update ability' do
    before do
      allow(job_item).to receive(:check_update_ability?).and_return(false)
    end

    it 'does not open the version' do
      job.perform_now

      expect(VersionService).not_to have_received(:openable?)
      expect(VersionService).not_to have_received(:open)
    end
  end
end
