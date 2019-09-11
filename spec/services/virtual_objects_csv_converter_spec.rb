# frozen_string_literal: true

require 'rails_helper'

RSpec.describe VirtualObjectsCsvConverter do
  let(:csv) { "parent1,child1,child2\nparent2,child3,child4,child5" }

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

    it 'has a csv_string attribute' do
      expect(instance.csv_string).to eq(csv)
    end
  end

  describe '#convert' do
    subject(:service) { described_class.new(csv_string: csv) }

    it 'parses a CSV string' do
      expect(subject.convert).to eq(
        virtual_objects: [
          {
            parent_id: 'parent1',
            child_ids: %w(child1 child2)
          },
          {
            parent_id: 'parent2',
            child_ids: %w(child3 child4 child5)
          }
        ]
      )
    end

    context 'with rows containing blank values' do
      let(:csv) { "parent1,,,,child1,,,child2\nparent2,,child3,,,,,child4,,,,child5,,,,,," }

      it 'drops blank values and works as expected' do
        expect(subject.convert).to eq(
          virtual_objects: [
            {
              parent_id: 'parent1',
              child_ids: %w(child1 child2)
            },
            {
              parent_id: 'parent2',
              child_ids: %w(child3 child4 child5)
            }
          ]
        )
      end
    end

    context 'with a one-row CSV' do
      let(:csv) { ',,parent1,,,,child1,,,child2,,,' }

      it 'works as expected' do
        expect(subject.convert).to eq(
          virtual_objects: [
            {
              parent_id: 'parent1',
              child_ids: %w(child1 child2)
            }
          ]
        )
      end
    end
  end
end
