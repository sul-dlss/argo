# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DorServices::Client do
  subject(:client) { described_class.new(params: params) }

  let(:params) { { foo: 'bar' } }

  describe '.register' do
    it 'calls #register on a new instance' do
      expect_any_instance_of(described_class).to receive(:register)
      described_class.register(params: params)
    end
  end

  describe '#new' do
    it 'has a params attr' do
      expect(client.params).to eq params
    end
  end

  describe '#register' do
    before do
      allow(client).to receive(:connection).and_return(fake_connection)
      allow(fake_connection).to receive(:post).and_yield(fake_request).and_return(fake_response)
    end

    let(:fake_connection) { double }
    let(:fake_request) do
      double(url: nil, headers: fake_headers, 'body=' => nil)
    end
    let(:fake_headers) { {} }

    context 'when API request succeeds' do
      let(:fake_response) do
        double(body: '{"pid":"druid:123"}',
               success?: true)
      end

      it 'posts params as json' do
        expect(fake_request).to receive(:url).with('v1/objects')
        expect(fake_request).to receive(:headers).and_return(fake_headers)
        expect(fake_request).to receive(:body=).with('{"foo":"bar"}')
        expect(fake_headers).to receive(:[]=).with('Content-Type', 'application/json')
        expect(client.register[:pid]).to eq('druid:123')
        expect(fake_connection).to have_received(:post).once
      end
    end

    context 'when API request fails' do
      let(:fake_response) do
        double(body: '',
               success?: false,
               reason_phrase: 'object already exists',
               status: '409')
      end

      it 'raises an error' do
        expect { client.register[:pid] }.to raise_error('object already exists: 409 ()')
        expect(fake_connection).to have_received(:post).once
      end
    end
  end
end
