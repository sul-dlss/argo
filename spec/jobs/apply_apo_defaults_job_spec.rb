# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplyApoDefaultsJob do
  subject(:job) do
    described_class.new(bulk_action.id, druids: [druid])
  end

  let(:druid) { 'druid:bb111cc2222' }
  let(:bulk_action) { create(:bulk_action) }
  let(:object_client) { instance_double(Dor::Services::Client::Object, apply_admin_policy_defaults: true) }

  let(:job_item) do
    described_class::ApplyApoDefaultsJobItem.new(druid: druid, index: 0, job: job).tap do |job_item|
      allow(job_item).to receive(:open_new_version_if_needed!)
      allow(job_item).to receive(:close_version_if_needed!)
      allow(job_item).to receive(:check_update_ability?).and_return(true)
    end
  end

  let(:log) { instance_double(File, puts: nil, close: true) }

  before do
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
    allow_any_instance_of(BulkAction).to receive(:open_log_file).and_return(log) # rubocop:disable RSpec/AnyInstance

    allow(described_class::ApplyApoDefaultsJobItem).to receive(:new).and_return(job_item)
  end

  it 'performs the job' do
    job.perform_now

    expect(job_item).to have_received(:check_update_ability?)
    expect(job_item).to have_received(:open_new_version_if_needed!).with(description: 'Applied admin policy defaults')
    expect(object_client).to have_received(:apply_admin_policy_defaults)
    expect(job_item).to have_received(:close_version_if_needed!)

    expect(log).to have_received(:puts).with(/Successfully applied defaults for druid:bb111cc2222/)
  end

  context 'when not authorized to update' do
    before do
      allow(job_item).to receive(:check_update_ability?).and_return(false)
    end

    it 'does not apply defaults' do
      job.perform_now

      expect(object_client).not_to have_received(:apply_admin_policy_defaults)
    end
  end
end
