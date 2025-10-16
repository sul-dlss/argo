# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ManageEmbargoesJob do
  subject(:job) { described_class.new(bulk_action.id, csv_file:) }

  let(:bulk_action) { create(:bulk_action) }
  let(:druid) { 'druid:bb111cc2222' }

  let(:druids) { %w[druid:bb111cc2222 druid:cc111dd2222 druid:dd111ff2222] }

  let(:log) { StringIO.new }

  let(:cocina_object) { build(:dro_with_metadata, id: druid) }

  let(:csv_file) do
    [
      'druid,release_date,view,download',
      [druid, release_date, *rights].join(',')
    ].join("\n")
  end
  let(:release_date) { '2040-04-04' }
  let(:rights) { %w[world world] }
  let(:row) { CSV.parse(csv_file, headers: true).first }

  let(:job_item) do
    described_class::ManageEmbargoesJobItem.new(druid: druid, index: 2, job: job, row:).tap do |job_item|
      allow(job_item).to receive(:open_new_version_if_needed!)
      allow(job_item).to receive(:close_version_if_needed!)
      allow(job_item).to receive_messages(check_update_ability?: true, cocina_object: cocina_object)
    end
  end

  let(:embargo_form) { instance_double(EmbargoForm, validate: true, save: true) }

  before do
    allow(described_class::ManageEmbargoesJobItem).to receive(:new).and_return(job_item)
    allow_any_instance_of(BulkAction).to receive(:open_log_file).and_return(log) # rubocop:disable RSpec/AnyInstance
    allow(EmbargoForm).to receive(:new).and_return(embargo_form)
  end

  it 'performs the job' do
    job.perform_now

    expect(job_item).to have_received(:check_update_ability?)
    expect(job_item).to have_received(:open_new_version_if_needed!).with(description: 'Manage embargo')

    expect(EmbargoForm).to have_received(:new).with(cocina_object)
    expect(embargo_form).to have_received(:validate).with({ release_date: DateTime.parse(release_date), view_access: rights[0], download_access: rights[1], access_location: nil })
    expect(embargo_form).to have_received(:save)

    expect(job_item).to have_received(:close_version_if_needed!)

    expect(bulk_action.reload.druid_count_total).to eq 1
    expect(bulk_action.druid_count_success).to eq 1
    expect(bulk_action.druid_count_fail).to eq 0
  end

  context 'when the user is not authorized to modify the object' do
    before do
      allow(job_item).to receive(:check_update_ability?).and_return(false)
    end

    it 'does not update the embargo' do
      job.perform_now

      expect(job_item).not_to have_received(:open_new_version_if_needed!)
    end
  end

  context 'when the release date is invalid' do
    let(:release_date) { 'invalid-date' }

    it 'does not update the embargo' do
      job.perform_now

      expect(EmbargoForm).not_to have_received(:new).with(cocina_object)

      expect(bulk_action.reload.druid_count_total).to eq 1
      expect(bulk_action.druid_count_success).to eq 0
      expect(bulk_action.druid_count_fail).to eq 1

      expect(log.string).to include('is not a valid date')
    end
  end

  context 'when the embargo form is invalid' do
    before do
      allow(embargo_form).to receive_messages(validate: false,
                                              errors: instance_double(ActiveModel::Errors, full_messages: ['Download access "nobody" is not a valid option']))
    end

    it 'does not update the embargo' do
      job.perform_now

      expect(embargo_form).not_to have_received(:save)

      expect(bulk_action.reload.druid_count_total).to eq 1
      expect(bulk_action.druid_count_success).to eq 0
      expect(bulk_action.druid_count_fail).to eq 1

      expect(log.string).to include('Download access "nobody" is not a valid option')
    end
  end
end
