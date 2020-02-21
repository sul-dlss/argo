# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TechmdService do
  describe '.techmd_for' do
    let(:techmd) { described_class.techmd_for(druid: 'druid:abc123xyz') }

    let(:url) { 'http://localhost:3005/v1/technical-metadata/druid/druid:abc123xyz' }

    context 'when service returns OK' do
      let(:response) { instance_double(ActionDispatch::Response, status: 200, body: '[{"foo": "bar"}]') }

      before do
        allow(Faraday).to receive(:get).with(url).and_return(response)
      end

      it 'returns techmd' do
        expect(techmd).to eq([{ 'foo' => 'bar' }])
      end
    end

    context 'when service return 404' do
      let(:response) { instance_double(ActionDispatch::Response, status: 404) }

      before do
        allow(Faraday).to receive(:get).with(url).and_return(response)
      end

      it 'returns empty techmd' do
        expect(techmd).to eq([])
      end
    end

    context 'when service returns other status' do
      let(:response) { instance_double(ActionDispatch::Response, status: 500, body: nil) }

      before do
        allow(Faraday).to receive(:get).with(url).and_return(response)
      end

      it 'raises' do
        expect { techmd }.to raise_error(/Unexpected response/)
      end
    end
  end
end
