# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActionJobItem do
  subject(:bulk_action_item) { described_class.new(druid:, index: 2, job:) }

  let(:druid) { 'druid:bb111cc2222' }

  let(:job) { instance_double(BulkActionJob, user: 'a_user', ability:, close_version?: close_version) }
  let(:ability) { instance_double(Ability) }
  let(:close_version) { true }

  describe '.success!' do
    before do
      allow(job).to receive(:success!)
    end

    it 'calls job.success!' do
      bulk_action_item.success!(message: 'Testing successful')
      expect(job).to have_received(:success!).with(druid:, message: 'Testing successful')
    end
  end

  describe '.failure!' do
    before do
      allow(job).to receive(:failure!)
    end

    it 'calls job.failure!' do
      bulk_action_item.failure!(message: 'Testing failed')
      expect(job).to have_received(:failure!).with(druid:, message: 'Testing failed')
    end
  end

  describe '.cocina_object' do
    let(:cocina_object) { instance_double(Cocina::Models::DRO) }

    before do
      allow(Repository).to receive(:find).with(druid).and_return(cocina_object)
    end

    it 'returns the cocina object' do
      expect(bulk_action_item.cocina_object).to eq cocina_object
    end
  end

  describe '.open_new_version_if_needed!' do
    before do
      allow(job).to receive(:log)
    end

    context 'when version is already open' do
      before do
        allow(VersionService).to receive(:open?).with(druid:).and_return(true)
        allow(VersionService).to receive(:open)
      end

      it 'does not open a new version' do
        bulk_action_item.open_new_version_if_needed!(description: 'Testing open version')
        expect(VersionService).not_to have_received(:open)
        expect(job).not_to have_received(:log)
      end
    end

    context 'when version is not open but openable' do
      let(:cocina_object) { instance_double(Cocina::Models::DRO, version: 2) }

      before do
        allow(VersionService).to receive(:open?).with(druid:).and_return(false)
        allow(VersionService).to receive(:openable?).with(druid:).and_return(true)
        allow(VersionService).to receive(:open).and_return(cocina_object)
      end

      it 'opens a new version' do
        bulk_action_item.open_new_version_if_needed!(description: 'Testing open version')
        expect(VersionService).to have_received(:open).with(druid:, description: 'Testing open version', opening_user_name: 'a_user')
        expect(job).to have_received(:log).with('Opened new version (Testing open version)')
        expect(bulk_action_item.cocina_object).to eq cocina_object
      end
    end

    context 'when version is not openable' do
      before do
        allow(VersionService).to receive(:open?).with(druid:).and_return(false)
        allow(VersionService).to receive(:openable?).with(druid:).and_return(false)
        allow(VersionService).to receive(:open)
      end

      it 'raises an error' do
        expect { bulk_action_item.open_new_version_if_needed!(description: 'Testing open version') }.to raise_error('Unable to open new version')
        expect(VersionService).not_to have_received(:open)
        expect(job).not_to have_received(:log)
      end
    end
  end

  describe '.close_version_if_needed!' do
    let(:cocina_object) { instance_double(Cocina::Models::DRO, version: 2) }

    before do
      allow(job).to receive(:log)
      allow(Repository).to receive(:find).with(druid).and_return(cocina_object)
    end

    context 'when version is 1' do
      let(:cocina_object) { instance_double(Cocina::Models::DRO, version: 1) }

      before do
        allow(VersionService).to receive(:closed?).with(druid:).and_return(false)
        allow(VersionService).to receive(:close)
      end

      it 'does not close the version' do
        bulk_action_item.close_version_if_needed!
        expect(VersionService).not_to have_received(:close)
      end
    end

    context 'when already closed' do
      before do
        allow(VersionService).to receive(:closed?).and_return(true)
        allow(VersionService).to receive(:close)
      end

      it 'does not close the version' do
        bulk_action_item.close_version_if_needed!
        expect(VersionService).not_to have_received(:close)
        expect(job).to have_received(:log).with('Version already closed')
      end
    end

    context 'when closeable' do
      before do
        allow(VersionService).to receive_messages(closed?: false, closeable?: true)
        allow(VersionService).to receive(:close)
      end

      it 'closes the version' do
        bulk_action_item.close_version_if_needed!
        expect(VersionService).to have_received(:close).with(druid:)
        expect(job).to have_received(:log).with('Closed version')
      end
    end

    context 'when not closeable' do
      before do
        allow(VersionService).to receive_messages(closed?: false, closeable?: false)
        allow(VersionService).to receive(:close)
      end

      it 'raises an error' do
        expect { bulk_action_item.close_version_if_needed! }.to raise_error('Unable to close version')
        expect(VersionService).not_to have_received(:close)
      end
    end

    context 'when user did not request version be closed' do
      let(:close_version) { false }

      before do
        allow(VersionService).to receive_messages(closed?: false)
      end

      it 'does not close the version' do
        bulk_action_item.close_version_if_needed!
        expect(VersionService).not_to have_received(:closed?)
        expect(job).not_to have_received(:log)
      end
    end
  end

  describe '.check_update_ability?' do
    let(:cocina_object) { instance_double(Cocina::Models::DRO) }

    before do
      allow(Repository).to receive(:find).with(druid).and_return(cocina_object)
      allow(job).to receive(:failure!)
    end

    context 'when can update' do
      before do
        allow(ability).to receive(:can?).and_return(true)
      end

      it 'returns true' do
        expect(bulk_action_item.check_update_ability?).to be true
        expect(ability).to have_received(:can?).with(:update, cocina_object)
      end
    end

    context 'when cannot update' do
      before do
        allow(ability).to receive(:can?).and_return(false)
      end

      it 'returns false' do
        expect(bulk_action_item.check_update_ability?).to be false
        expect(ability).to have_received(:can?).with(:update, cocina_object)
        expect(job).to have_received(:failure!).with(druid:, message: 'Not authorized to update')
      end
    end
  end

  describe '.check_read_ability?' do
    let(:cocina_object) { instance_double(Cocina::Models::DRO) }

    before do
      allow(Repository).to receive(:find).with(druid).and_return(cocina_object)
      allow(job).to receive(:failure!)
    end

    context 'when can read' do
      before do
        allow(ability).to receive(:can?).and_return(true)
      end

      it 'returns true' do
        expect(bulk_action_item.check_read_ability?).to be true
        expect(ability).to have_received(:can?).with(:read, cocina_object)
      end
    end

    context 'when cannot read' do
      before do
        allow(ability).to receive(:can?).and_return(false)
      end

      it 'returns false' do
        expect(bulk_action_item.check_read_ability?).to be false
        expect(ability).to have_received(:can?).with(:read, cocina_object)
        expect(job).to have_received(:failure!).with(druid:, message: 'Not authorized to read')
      end
    end
  end
end
