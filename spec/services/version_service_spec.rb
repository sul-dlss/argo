# frozen_string_literal: true

require 'rails_helper'

RSpec.describe VersionService do
  subject(:service) { described_class.new(druid:) }

  let(:druid) { 'druid:bg139xz7624' }

  let(:object_client) { instance_double(Dor::Services::Client::Object, version: version_client) }
  let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, status:) }
  let(:status) { instance_double(Dor::Services::Client::ObjectVersion::VersionStatus) }

  before do
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
  end

  describe '.close' do
    before do
      allow(described_class).to receive(:new).and_return(service)
      allow(service).to receive(:close)
    end

    it 'calls #close on a new instance' do
      described_class.close(druid:)
      expect(service).to have_received(:close).once
    end
  end

  describe '#open' do
    let(:options) do
      {
        description: 'best version ever',
        opening_user_name: 'mjgiarlo'
      }
    end

    before do
      allow(version_client).to receive(:open)
    end

    it 'delegates to the version client' do
      service.open(**options)
      expect(version_client).to have_received(:open).with(**options).once
    end
  end

  describe '#close' do
    before do
      allow(version_client).to receive(:close)
    end

    it 'delegates to the version client' do
      service.close
      expect(version_client).to have_received(:close).once
    end
  end

  describe 'status methods' do
    it 'delegates to the version client' do
      %i[open? openable? assembling? text_extracting? accessioning? closed? closeable? version].each do |method|
        allow(status).to receive(method)
        service.send(method)
        expect(status).to have_received(method).once
      end
    end
  end
end
