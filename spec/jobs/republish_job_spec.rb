# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RepublishJob do
  subject(:job) { described_class.new(bulk_action.id, druids: [druid]) }

  let(:druid) { 'druid:bb111cc2222' }
  let(:bulk_action) { create(:bulk_action) }

  let(:cocina_object) { instance_double(Cocina::Models::DRO) }

  let(:job_item) do
    described_class::RepublishJobItem.new(druid: druid, index: 0, job: job).tap do |job_item|
      allow(job_item).to receive(:cocina_object).and_return(cocina_object)
    end
  end

  let(:object_client) { instance_double(Dor::Services::Client::Object, publish: true) }

  before do
    allow(described_class::RepublishJobItem).to receive(:new).and_return(job_item)
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
    allow(WorkflowService).to receive(:published?).and_return(true)

    allow(cocina_object).to receive_messages(admin_policy?: false, type: Cocina::Models::ObjectType.book)
  end

  after do
    FileUtils.rm(bulk_action.log_name)
  end

  it 'performs the job' do
    job.perform_now

    expect(WorkflowService).to have_received(:published?).with(druid: druid)
    expect(object_client).to have_received(:publish).with(lane_id: 'low')

    expect(bulk_action.reload.druid_count_total).to eq(1)
    expect(bulk_action.druid_count_fail).to eq(0)
    expect(bulk_action.druid_count_success).to eq(1)
  end

  context 'with never published item' do
    before do
      allow(WorkflowService).to receive(:published?).and_return(false)
    end

    it 'does not publish the object' do
      job.perform_now

      expect(object_client).not_to have_received(:publish)

      expect(bulk_action.reload.druid_count_total).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(1)
      expect(bulk_action.druid_count_success).to eq(0)
    end
  end

  context 'with an APO' do
    before do
      allow(cocina_object).to receive(:admin_policy?).and_return(true)
    end

    it 'does not publish the object' do
      job.perform_now

      expect(object_client).not_to have_received(:publish)

      expect(bulk_action.reload.druid_count_total).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(1)
      expect(bulk_action.druid_count_success).to eq(0)
    end
  end

  context 'with an agreement' do
    before do
      allow(cocina_object).to receive(:type).and_return(Cocina::Models::ObjectType.agreement)
    end

    it 'does not publish the object' do
      job.perform_now

      expect(object_client).not_to have_received(:publish)

      expect(bulk_action.reload.druid_count_total).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(1)
      expect(bulk_action.druid_count_success).to eq(0)
    end
  end
end
