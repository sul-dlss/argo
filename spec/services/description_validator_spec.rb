# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DescriptionValidator do
  describe '#valid?' do
    let(:instance) { described_class.new(CSV.parse(csv, headers: true)) }

    context 'for all jobs' do
      context 'with duplicate columns' do
        let(:csv) { 'druid,title1.value,title2.value,title1.value,title2.value,title3.value' }

        it 'finds errors' do
          expect(instance.valid?).to be false
          expect(instance.errors).to eq [
            'Duplicate column headers: The header title1.value should occur only once.',
            'Duplicate column headers: The header title2.value should occur only once.'
          ]
        end
      end

      context 'with missing title1.value column' do
        let(:csv) { 'druid,event1.note1.source.value' }

        it 'finds errors' do
          expect(instance.valid?).to be false
          expect(instance.errors).to eq ['Title column not found.']
        end
      end

      context 'with missing title1.structureValue1.value column' do
        let(:csv) { 'druid,title1.structureValue1.type' }

        it 'finds errors' do
          expect(instance.valid?).to be false
          expect(instance.errors).to eq ['Title column not found.']
        end
      end

      context 'with missing title1.structureValue1.type column' do
        let(:csv) { 'druid,title1.structureValue1.value' }

        it 'finds errors' do
          expect(instance.valid?).to be false
          expect(instance.errors).to eq ['Title column not found.']
        end
      end

      context 'with a title1.structureValue1.value and a title1.structureValue1.type column' do
        let(:csv) { 'druid,title1.structureValue1.type,title1.structureValue1.value' }

        it 'validates' do
          expect(instance.valid?).to be true
        end
      end

      context 'with a title1.value column' do
        let(:csv) { 'druid,title1.value' }

        it 'validates' do
          expect(instance.valid?).to be true
        end
      end
    end

    context 'for bulk jobs' do
      let(:instance) { described_class.new(CSV.parse(csv, headers: true), bulk_job: true) }

      context 'with missing druid header' do
        let(:csv) { 'title1.value,title2.value,title3.value' }

        it 'finds errors' do
          expect(instance.valid?).to be false
          expect(instance.errors).to eq ['Druid column not found.']
        end
      end

      context 'with missing druid in a row' do
        let(:csv) do
          <<~CSV
            druid,title1.value,title2.value,title3.value
            druid:ab123cd4567,cool,stuff,here
            ,missing,druid,here
            druid:cd456de5678,value,,
          CSV
        end

        it 'finds errors' do
          expect(instance.valid?).to be false
          expect(instance.errors).to eq ['Missing druid: No druid present in row 3.']
        end
      end

      context 'with duplicate druids in separate rows' do
        let(:csv) do
          <<~CSV
            druid,title1.value,title2.value,title3.value
            druid:ab123cd4567,cool,stuff,here
            druid:ab123cd4567,cool2,stuff2,here2
            druid:cd456de5678,value,,
          CSV
        end

        it 'finds errors' do
          expect(instance.valid?).to be false
          expect(instance.errors).to eq ['Duplicate druids: The druid "druid:ab123cd4567" should occur only once.']
        end
      end
    end

    context 'for non bulk jobs' do
      let(:instance) { described_class.new(CSV.parse(csv, headers: true), bulk_job: false) }

      context 'with missing druid header' do
        let(:csv) { 'title1.value,title2.value,title3.value' }
        let(:bulk_job) { false }

        it 'validates' do
          expect(instance.valid?).to be true
        end
      end

      context 'with missing druid in a row' do
        let(:csv) do
          <<~CSV
            druid,title1.value,title2.value,title3.value
            ,missing,druid,here
          CSV
        end

        it 'validates' do
          expect(instance.valid?).to be true
        end
      end
    end
  end
end
