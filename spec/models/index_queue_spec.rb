# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IndexQueue do
  subject { described_class.new }

  let(:good_response) { { value: 100 }.to_json }

  describe '#depth' do
    describe 'when response fails' do
      it 'with SocketError' do
        expect(Faraday).to receive(:get).and_raise(SocketError)
        expect(subject.depth).to be_nil
      end
    end

    describe 'when response is not JSON' do
      it 'cannot be parsed' do
        expect(subject).to receive(:response).and_return 'not JSON'
        expect(subject.depth).to be_nil
      end
    end

    describe 'when response is nil' do
      it 'cannot be parsed' do
        expect(subject).to receive(:response).and_return nil
        expect(subject.depth).to be_nil
      end
    end

    describe 'when response is not string' do
      it 'cannot be parsed' do
        expect(subject).to receive(:response).and_return []
        expect(subject.depth).to be_nil
      end
    end

    describe 'when response is not expected JSON' do
      it 'cannot be parsed' do
        expect(subject).to receive(:response)
          .and_return({ test: 'test' }.to_json)
        expect(subject.depth).to be_nil
      end
    end

    describe 'with expected response' do
      it 'returns response integer' do
        expect(subject).to receive(:response).and_return good_response
        expect(subject.depth).to eq 100
      end
    end
  end
end
