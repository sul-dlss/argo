# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SetRightsJob do
  subject(:job) { described_class.new(bulk_action.id, druids: [druid], **params) }

  let(:druid) { 'druid:bb111cc2222' }
  let(:bulk_action) { create(:bulk_action) }

  let(:job_item) do
    described_class::SetRightsJobItem.new(druid: druid, index: 0, job: job).tap do |job_item|
      allow(job_item).to receive(:open_new_version_if_needed!)
      allow(job_item).to receive(:close_version_if_needed!)
      allow(job_item).to receive_messages(check_update_ability?: true, cocina_object: cocina_object)
    end
  end

  let(:cocina_object) { instance_double(Cocina::Models::DROWithMetadata, collection?: false) }

  let(:change_set) { instance_double(ItemChangeSet, validate: true, save: true) }

  let(:log) { StringIO.new }

  let(:params) do
    {
      view_access: 'world',
      download_access: 'world'
    }
  end

  before do
    allow(described_class::SetRightsJobItem).to receive(:new).and_return(job_item)
    allow_any_instance_of(BulkAction).to receive(:open_log_file).and_return(log) # rubocop:disable RSpec/AnyInstance
    allow(ItemChangeSet).to receive(:new).and_return(change_set)
  end

  it 'performs the job' do
    subject.perform_now

    expect(job_item).to have_received(:check_update_ability?)
    expect(job_item).to have_received(:open_new_version_if_needed!).with(description: 'Updating rights')
    expect(change_set).to have_received(:validate).with(view_access: 'world', download_access: 'world')
    expect(change_set).to have_received(:save)
    expect(job_item).to have_received(:close_version_if_needed!)

    expect(bulk_action.reload.druid_count_total).to eq 1
    expect(bulk_action.druid_count_success).to eq 1
    expect(bulk_action.druid_count_fail).to eq 0
  end

  context 'when a collection' do
    let(:cocina_object) { instance_double(Cocina::Models::Collection, collection?: true) }
    let(:change_set) { instance_double(CollectionChangeSet, validate: true, save: true) }

    let(:params) do
      {
        view_access: 'location',
        download_access: 'world'
      }
    end

    before do
      allow(CollectionChangeSet).to receive(:new).and_return(change_set)
    end

    it 'limits view access to dark or world' do
      subject.perform_now

      expect(change_set).to have_received(:validate).with(view_access: 'world')
      expect(change_set).to have_received(:save)
    end
  end

  context 'when the user does not have update ability' do
    before do
      allow(job_item).to receive(:check_update_ability?).and_return(false)
    end

    it 'does not perform the update' do
      subject.perform_now

      expect(ItemChangeSet).not_to have_received(:new)
    end
  end
end
