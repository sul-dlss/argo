# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DorServices::Client do
  subject(:client) { described_class.instance }

  let(:fake_connection) { double }

  describe '.register' do
    let(:params) { { foo: 'bar' } }

    it 'calls #register on a new instance' do
      expect(described_class.instance).to receive(:register)
      described_class.register(params: params)
    end
  end

  describe '.retrieve_file' do
    it 'calls #retrieve_file on a new instance' do
      expect(described_class.instance).to receive(:retrieve_file)
      described_class.retrieve_file(object: 'druid:123', filename: 'M1090_S15_B01_F04_0073.jp2')
    end
  end

  describe '.list_files' do
    it 'calls #list_files on a new instance' do
      expect(described_class.instance).to receive(:list_files)
      described_class.list_files(object: 'druid:123')
    end
  end

  describe '#register' do
    let(:params) { { foo: 'bar' } }

    context 'when API request succeeds' do
      before do
        stub_request(:post, 'https://dor-services.example.com/v1/objects')
          .with(
            body: '{"foo":"bar"}',
            headers: { 'Content-Type' => 'application/json', 'Accept' => 'application/json' }
          )
          .to_return(status: 200, body: '{"pid":"druid:123"}', headers: {})
      end

      it 'posts params as json' do
        expect(client.register(params: params)[:pid]).to eq 'druid:123'
      end
    end

    context 'when API request fails' do
      before do
        stub_request(:post, 'https://dor-services.example.com/v1/objects')
          .with(
            body: '{"foo":"bar"}',
            headers: { 'Content-Type' => 'application/json', 'Accept' => 'application/json' }
          )
          .to_return(status: [409, 'object already exists'])
      end

      it 'raises an error' do
        expect { client.register(params: params) }.to raise_error('object already exists: 409 ()')
      end
    end
  end

  describe '#list_files' do
    subject { client.list_files(object: 'druid:ck546xs5106') }
    context 'when the response is 200' do
      let(:body) do
        <<~JSON
          {"items":[{"id":"olemiss1.jp2","name":"olemiss1.jp2","selfLink":"https://dor-services-stage.stanford.edu/v1/objects/druid:ck546xs5106/contents/olemiss1.jp2"},
          {"id":"olemiss1.jpeg","name":"olemiss1.jpeg","selfLink":"https://dor-services-stage.stanford.edu/v1/objects/druid:ck546xs5106/contents/olemiss1.jpeg"},
          {"id":"olemiss1v.jp2","name":"olemiss1v.jp2","selfLink":"https://dor-services-stage.stanford.edu/v1/objects/druid:ck546xs5106/contents/olemiss1v.jp2"},
          {"id":"olemiss1v.jpeg","name":"olemiss1v.jpeg","selfLink":"https://dor-services-stage.stanford.edu/v1/objects/druid:ck546xs5106/contents/olemiss1v.jpeg"}]}
        JSON
      end

      before do
        stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:ck546xs5106/contents')
          .to_return(status: 200, body: body)
      end

      it { is_expected.to eq ['olemiss1.jp2', 'olemiss1.jpeg', 'olemiss1v.jp2', 'olemiss1v.jpeg'] }
    end

    context 'when the response is 404' do
      before do
        stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:ck546xs5106/contents')
          .to_return(status: 404, body: '')
      end

      it { is_expected.to eq [] }
    end
  end

  describe '#retrieve_file' do
    subject { client.retrieve_file(object: 'druid:ck546xs5106', filename: 'olemiss1v.jp2') }
    context 'when the response is 200' do
      let(:body) do
        <<~BODY
          This is all the stuff in the file
        BODY
      end

      before do
        stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:ck546xs5106/contents/olemiss1v.jp2')
          .to_return(status: 200, body: body)
      end

      it { is_expected.to eq "This is all the stuff in the file\n" }
    end

    context 'when the response is 404' do
      before do
        stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:ck546xs5106/contents/olemiss1v.jp2')
          .to_return(status: 404, body: '')
      end

      it { is_expected.to be_nil }
    end
  end
end
