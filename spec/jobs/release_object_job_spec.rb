# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReleaseObjectJob do
  subject(:job) { described_class.new(bulk_action.id, **params) }

  let(:druid) { 'druid:bb111cc2222' }
  let(:params) do
    {
      druids: [druid],
      to: 'SEARCHWORKS',
      who: 'bergeraj',
      what: 'self',
      tag: 'true'
    }
  end
  let(:bulk_action) { create(:bulk_action) }
  let(:cocina_object) { instance_double(Cocina::Models::DRO, version:) }
  let(:version) { 2 }

  let(:log) { StringIO.new }

  let(:job_item) do
    described_class::ReleaseObjectJobItem.new(druid: druid, index: 0, job: job).tap do |job_item|
      allow(job_item).to receive_messages(check_update_ability?: true, cocina_object: cocina_object)
    end
  end
  let(:object_client) { instance_double(Dor::Services::Client::Object, release_tags: release_tags_client) }
  let(:release_tags_client) { instance_double(Dor::Services::Client::ReleaseTags, create: true) }

  before do
    allow(described_class::ReleaseObjectJobItem).to receive(:new).and_return(job_item)
    allow(WorkflowService).to receive(:published?).and_return(true)
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
    allow_any_instance_of(BulkAction).to receive(:open_log_file).and_return(log) # rubocop:disable RSpec/AnyInstance
  end

  it 'performs the job' do
    job.perform_now

    expect(job_item).to have_received(:check_update_ability?)
    expect(WorkflowService).to have_received(:published?).with(druid: druid)
    expect(release_tags_client).to have_received(:create).with(tag: an_instance_of(Dor::Services::Client::ReleaseTag))

    expect(bulk_action.reload.druid_count_total).to eq(1)
    expect(bulk_action.druid_count_fail).to eq(0)
    expect(bulk_action.druid_count_success).to eq(1)
  end

  context 'when the user lacks update ability' do
    before do
      allow(job_item).to receive(:check_update_ability?).and_return(false)
    end

    it 'does not release the object' do
      job.perform_now

      expect(WorkflowService).not_to have_received(:published?)
      expect(release_tags_client).not_to have_received(:create)
    end
  end

  context 'when the object has never been published' do
    before do
      allow(WorkflowService).to receive(:published?).and_return(false)
    end

    it 'does not release the object' do
      job.perform_now

      expect(release_tags_client).not_to have_received(:create)

      expect(bulk_action.reload.druid_count_total).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(1)
      expect(bulk_action.druid_count_success).to eq(0)
    end
  end
end
