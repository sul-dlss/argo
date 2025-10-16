# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AddWorkflowJob do
  subject(:job) { described_class.new(bulk_action.id, druids: [druid], workflow:) }

  let(:druid) { 'druid:bb111cc2222' }
  let(:workflow) { 'accessionWF' }
  let(:version) { 1 }

  let(:bulk_action) { create(:bulk_action) }

  let(:job_item) do
    described_class::AddWorkflowJobItem.new(druid: druid, index: 0, job: job).tap do |job_item|
      allow(job_item).to receive(:open_new_version_if_needed!)
      allow(job_item).to receive_messages(check_update_ability?: true, cocina_object: cocina_object)
    end
  end

  let(:cocina_object) { instance_double(Cocina::Models::DRO, version:) }
  let(:object_client) { instance_double(Dor::Services::Client::Object, workflow: wf_client) }
  let(:wf_client) { instance_double(Dor::Services::Client::ObjectWorkflow, create: true) }

  before do
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
    allow(described_class::AddWorkflowJobItem).to receive(:new).and_return(job_item)
    allow(WorkflowService).to receive(:workflow_active?).and_return(false)
  end

  it 'performs the job' do
    job.perform_now

    expect(job_item).to have_received(:check_update_ability?)
    expect(WorkflowService).to have_received(:workflow_active?).with(druid: druid, wf_name: workflow, version:)
    expect(job_item).to have_received(:open_new_version_if_needed!).with(description: 'Running accessionWF')
    expect(object_client).to have_received(:workflow).with(workflow)
    expect(wf_client).to have_received(:create).with(version: version)

    expect(bulk_action.reload.druid_count_total).to eq(1)
    expect(bulk_action.druid_count_success).to eq(1)
    expect(bulk_action.druid_count_fail).to eq(0)
  end

  context 'when the user is not authorized to update' do
    before do
      allow(job_item).to receive(:check_update_ability?).and_return(false)
    end

    it 'does not create a workflow' do
      job.perform_now

      expect(wf_client).not_to have_received(:create)
    end
  end

  context 'when there is an active workflow' do
    before do
      allow(WorkflowService).to receive(:workflow_active?).and_return(true)
    end

    it 'does not create a workflow' do
      job.perform_now

      expect(wf_client).not_to have_received(:create)

      expect(bulk_action.reload.druid_count_total).to eq(1)
      expect(bulk_action.druid_count_success).to eq(0)
      expect(bulk_action.druid_count_fail).to eq(1)
    end
  end
end
