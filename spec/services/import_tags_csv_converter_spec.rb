# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ImportTagsCsvConverter do
  let(:csv) { "druid:bc123df4567,Tag : One\ndruid:df324kj9785,Tag : Uno : Dos,Something : Else" }

  describe '.convert' do
    let(:instance) { instance_double(described_class, convert: {}) }

    before do
      allow(described_class).to receive(:new).and_return(instance)
    end

    it 'creates an instance and calls `#convert`' do
      described_class.convert(csv_string: csv)
      expect(instance).to have_received(:convert).once
    end
  end

  describe '.new' do
    let(:instance) { described_class.new(csv_string: csv) }

    it 'has a private csv_string attribute' do
      expect(instance.send(:csv_string)).to eq(csv)
    end
  end

  describe '#convert' do
    subject(:service) { described_class.new(csv_string: csv) }

    it 'parses a CSV string' do
      expect(subject.convert).to eq(
        {
          'druid:bc123df4567' => ['Tag : One'],
          'druid:df324kj9785' => ['Tag : Uno : Dos', 'Something : Else']
        }
      )
    end

    context 'with bare druids' do
      let(:csv) { "bc123df4567,Tag : One\ndf324kj9785,Tag : Uno : Dos,Something : Else" }

      it 'prefixes druids and works as expected' do
        expect(subject.convert).to eq(
          {
            'druid:bc123df4567' => ['Tag : One'],
            'druid:df324kj9785' => ['Tag : Uno : Dos', 'Something : Else']
          }
        )
      end
    end

    context 'with a mix of druids with tags and druids without tags' do
      let(:csv) { "druid:bc123df4567,Tag : One\ndruid:df324kj9785" }

      it 'works as expected' do
        expect(subject.convert).to eq(
          {
            'druid:bc123df4567' => ['Tag : One'],
            'druid:df324kj9785' => []
          }
        )
      end
    end

    context 'with a mix of conditions' do
      let(:csv) { "bc123df4567,Tag : One\n\n\ndruid:bc234fg7890\ndruid:df324kj9785,Tag : Uno : Dos,Something : Else" }

      it 'filters out blank rows and works as expected' do
        expect(subject.convert).to eq(
          {
            'druid:bc123df4567' => ['Tag : One'],
            'druid:bc234fg7890' => [],
            'druid:df324kj9785' => ['Tag : Uno : Dos', 'Something : Else']
          }
        )
      end
    end

    context 'with a mix of conditions including multiple commas' do
      let(:csv) { "bc123df4567,Tag : One,,,,\n\n\ndruid:bc234fg7890\ndruid:df324kj9785,Tag : Uno : Dos,Something : Else" }

      it 'filters out blank rows and works as expected' do
        expect(subject.convert).to eq(
          {
            'druid:bc123df4567' => ['Tag : One'],
            'druid:bc234fg7890' => [],
            'druid:df324kj9785' => ['Tag : Uno : Dos', 'Something : Else']
          }
        )
      end
    end

    context 'with a one-row CSV' do
      let(:csv) { 'bc123df4567,Tag : One' }

      it 'works as expected' do
        expect(subject.convert).to eq(
          {
            'druid:bc123df4567' => ['Tag : One']
          }
        )
      end
    end
  end
end
