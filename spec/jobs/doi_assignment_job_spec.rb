# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DoiAssignmentJob do
  subject(:job) { described_class.new(bulk_action.id, druids: [druid]) }

  let(:ability) { instance_double(Ability, can?: can_assign_doi) }
  let(:bulk_action) { create(:bulk_action) }
  let(:can_assign_doi) { true }
  let(:cocina_object) { build(:dro_with_metadata, id: druid) }
  let(:datacite_validator) { instance_double(Datacite::Validators::CocinaValidator, valid?: datacite_valid, errors: ['whatever']) }
  let(:datacite_valid) { true }
  let(:druid) { 'druid:bb111cc2222' }
  let(:job_item) do
    described_class::DoiAssignmentJobItem.new(druid:, index: 0, job:).tap do |job_item|
      allow(job_item).to receive(:open_new_version_if_needed!)
      allow(job_item).to receive(:close_version_if_needed!)
      allow(job_item).to receive(:ability).and_return(ability)
      allow(job_item).to receive_messages(cocina_object:)
    end
  end
  let(:log) { instance_double(File, puts: nil, close: true) }
  let(:object_client) { instance_double(Dor::Services::Client::Object, update: true) }

  before do
    allow(described_class::DoiAssignmentJobItem).to receive(:new).and_return(job_item)
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
    allow_any_instance_of(BulkAction).to receive(:open_log_file).and_return(log) # rubocop:disable RSpec/AnyInstance
    allow(Datacite::Validators::CocinaValidator).to receive(:new).and_return(datacite_validator)
  end

  it 'assigns the DOI' do
    job.perform_now

    expect(job_item).to have_received(:ability).once
    expect(ability).to have_received(:can?).once
    expect(job_item).to have_received(:open_new_version_if_needed!).once.with(description: 'Assigned DOI')
    expect(object_client).to have_received(:update).once.with(params: cocina_object_with(identification: { doi: '10.80343/bb111cc2222' }))
    expect(job_item).to have_received(:close_version_if_needed!).once
    expect(datacite_validator).to have_received(:valid?).once

    expect(bulk_action.reload.druid_count_total).to eq(1)
    expect(bulk_action.druid_count_fail).to eq(0)
    expect(bulk_action.druid_count_success).to eq(1)
  end

  context 'when the user cannot assign DOIs' do
    let(:can_assign_doi) { false }

    it 'does not assign the DOI' do
      job.perform_now

      expect(object_client).not_to have_received(:update)

      expect(bulk_action.reload.druid_count_total).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(1)
      expect(bulk_action.druid_count_success).to eq(0)
    end
  end

  context 'when the object is not an item' do
    let(:cocina_object) { build(:collection_with_metadata, id: druid) }

    it 'does not assign the DOI' do
      job.perform_now

      expect(object_client).not_to have_received(:update)

      expect(bulk_action.reload.druid_count_total).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(1)
      expect(bulk_action.druid_count_success).to eq(0)
    end
  end

  context 'when the object maps to invalid DataCite metadata' do
    let(:datacite_valid) { false }

    it 'does not assign the DOI' do
      job.perform_now

      expect(object_client).not_to have_received(:update)

      expect(bulk_action.reload.druid_count_total).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(1)
      expect(bulk_action.druid_count_success).to eq(0)
    end
  end
end
