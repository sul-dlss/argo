# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StateService do
  let(:service) { described_class.new(cocina) }

  let(:druid) { 'bc123df4567' }
  let(:version_service) { instance_double(VersionService, version:) }
  let(:cocina) { instance_double(Cocina::Models::DRO, externalIdentifier: druid, version:) }
  let(:version) { 3 }

  before do
    allow(VersionService).to receive(:new).and_return(version_service)
  end

  describe '#object_state' do
    context 'when object is open, not assembling, not text extracting, but not closeable' do
      before do
        allow(version_service).to receive_messages(open?: true, closeable?: false, closed?: false, assembling?: false, text_extracting?: false)
      end

      it 'returns unlock_inactive' do
        expect(service.object_state).to eq :unlock_inactive
      end
    end

    context 'when object is open and assembling' do
      before do
        allow(version_service).to receive_messages(open?: true, closeable?: false, closed?: false, assembling?: true, text_extracting?: false)
      end

      it 'returns unlock_inactive' do
        expect(service.object_state).to eq :lock_assembling
      end
    end

    context 'when object is open and text extracting' do
      before do
        allow(version_service).to receive_messages(open?: true, closeable?: false, closed?: false, assembling?: false, text_extracting?: true)
      end

      it 'returns unlock_inactive' do
        expect(service.object_state).to eq :lock_assembling
      end
    end

    context 'when object is open and closeable' do
      before do
        allow(version_service).to receive_messages(open?: true, closeable?: true)
      end

      it 'returns unlock' do
        expect(service.object_state).to eq :unlock
      end
    end

    context 'when object is closed and not openable' do
      before do
        allow(version_service).to receive_messages(open?: false, closed?: true, openable?: false)
      end

      it 'returns lock_inactive' do
        expect(service.object_state).to eq :lock_inactive
      end
    end

    context 'when object is closed and openable' do
      before do
        allow(version_service).to receive_messages(open?: false, closed?: true, openable?: true)
      end

      it 'returns lock' do
        expect(service.object_state).to eq :lock
      end
    end
  end
end
