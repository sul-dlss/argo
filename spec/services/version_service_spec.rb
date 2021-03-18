# frozen_string_literal: true

require 'rails_helper'

RSpec.describe VersionService do
  subject(:service) { described_class.new(identifier: identifier) }

  let(:identifier) { 'druid:abc123xyz' }

  describe '.close' do
    before do
      allow(described_class).to receive(:new).and_return(service)
      allow(service).to receive(:close)
    end

    it 'calls #close on a new instance' do
      described_class.close(identifier: identifier)
      expect(service).to have_received(:close).once
    end
  end

  describe '#new' do
    it 'has an identifier attribute' do
      expect(service.identifier).to eq(identifier)
    end
  end

  describe '#open' do
    let(:version_client) { service.send(:version_client) }
    let(:options) do
      {
        significance: 'major',
        description: 'best version ever',
        opening_user_name: 'mjgiarlo'
      }
    end

    it 'delegates to the version client' do
      allow(version_client).to receive(:open)
      service.open(**options)
      expect(version_client).to have_received(:open).with(**options).once
    end
  end

  describe '#close' do
    let(:version_client) { service.send(:version_client) }

    it 'delegates to the version client' do
      allow(version_client).to receive(:close)
      service.close
      expect(version_client).to have_received(:close).once
    end
  end

  describe '#openable?' do
    let(:version_client) { service.send(:version_client) }

    it 'delegates to the version client' do
      allow(version_client).to receive(:openable?)
      service.openable?
      expect(version_client).to have_received(:openable?).once
    end
  end
end
