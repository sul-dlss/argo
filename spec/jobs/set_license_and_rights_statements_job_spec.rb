# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SetLicenseAndRightsStatementsJob do
  subject(:job) { described_class.new(bulk_action.id, druids: [druid], **params) }

  let(:bulk_action) { create(:bulk_action) }
  let(:druid) { 'druid:bb111cc2222' }
  let(:cocina_object) { instance_double(Cocina::Models::DROWithMetadata, dro?: true, collection?: false) }

  let(:log) { instance_double(File, puts: nil, close: true) }

  let(:job_item) do
    described_class::SetLicenseAndRightsStatementsJobItem.new(druid: druid, index: 0, job: job).tap do |job_item|
      allow(job_item).to receive(:open_new_version_if_needed!)
      allow(job_item).to receive(:close_version_if_needed!)
      allow(job_item).to receive_messages(check_update_ability?: true, cocina_object: cocina_object)
    end
  end

  let(:params) do
    {
      copyright_statement_option: '1',
      copyright_statement: copyright
    }
  end
  let(:change_set) { instance_double(ItemChangeSet, validate: true, changed?: true, save: true) }
  let(:copyright) { 'my copyright statement' }

  before do
    allow_any_instance_of(BulkAction).to receive(:open_log_file).and_return(log) # rubocop:disable RSpec/AnyInstance
    allow(described_class::SetLicenseAndRightsStatementsJobItem).to receive(:new).and_return(job_item)
    allow(ItemChangeSet).to receive(:new).and_return(change_set)
  end

  it 'performs the job' do
    job.perform_now

    expect(job_item).to have_received(:check_update_ability?)
    expect(ItemChangeSet).to have_received(:new).with(cocina_object).twice
    expect(change_set).to have_received(:validate).with(copyright:).twice
    expect(change_set).to have_received(:save)
    expect(job_item).to have_received(:open_new_version_if_needed!).with(description: 'Updated license, copyright statement, and/or use and reproduction statement')
    expect(job_item).to have_received(:close_version_if_needed!)

    expect(bulk_action.reload.druid_count_total).to eq(1)
    expect(bulk_action.druid_count_success).to eq(1)
    expect(bulk_action.druid_count_fail).to eq(0)
  end

  context 'when a collection' do
    let(:cocina_object) { build(:collection_with_metadata) }
    let(:change_set) { instance_double(CollectionChangeSet, validate: true, changed?: true, save: true) }

    before do
      allow(CollectionChangeSet).to receive(:new).and_return(change_set)
    end

    it 'performs the job with collection change set' do
      job.perform_now

      expect(CollectionChangeSet).to have_received(:new).with(cocina_object).twice
      expect(change_set).to have_received(:validate).with(copyright:).twice
      expect(change_set).to have_received(:save)
    end
  end

  context 'when an APO' do
    let(:cocina_object) { build(:admin_policy) }

    it 'fails the job' do
      job.perform_now

      expect(log).to have_received(:puts).with(%r{Not an item or collection \(https://cocina.sul.stanford.edu/models/admin_policy\)})

      expect(bulk_action.reload.druid_count_total).to eq(1)
      expect(bulk_action.druid_count_success).to eq(0)
      expect(bulk_action.druid_count_fail).to eq(1)
    end
  end

  context 'when the user is unauthorized' do
    before do
      allow(job_item).to receive(:check_update_ability?).and_return(false)
    end

    it 'fails the job' do
      job.perform_now

      expect(ItemChangeSet).not_to have_received(:new)
    end
  end

  context 'when no changes' do
    let(:change_set) { instance_double(ItemChangeSet, validate: true, changed?: false, save: true) }

    it 'logs no changes made' do
      job.perform_now

      expect(log).to have_received(:puts).with(/No changes made/)

      expect(bulk_action.reload.druid_count_total).to eq(1)
      expect(bulk_action.druid_count_success).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(0)
    end
  end

  context 'when no license' do
    let(:params) do
      {
        license_option: '1',
        license: ''
      }
    end

    it 'performs the job with no license' do
      job.perform_now

      expect(ItemChangeSet).to have_received(:new).with(cocina_object).twice
      expect(change_set).to have_received(:validate).with(license: '').twice
      expect(change_set).to have_received(:save)
    end
  end
end
