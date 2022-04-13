# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DescriptionValidator do
  describe '#valid?' do
    let(:instance) { described_class.new(CSV.parse(csv, headers: true), bulk_job: bulk_job) }
    let(:bulk_job) { true }

    context 'with duplicate columns' do
      let(:csv) { 'druid,title1:value,title2:value,title1:value,title2:value,title3:value' }

      it 'finds errors' do
        expect(instance.valid?).to be false
        expect(instance.errors).to eq [
          'Duplicate column headers: The header title1:value should occur only once.',
          'Duplicate column headers: The header title2:value should occur only once.'
        ]
      end
    end

    context 'with missing druid header in a bulk job' do
      let(:csv) { 'title1:value,title2:value,title3:value' }

      it 'finds errors' do
        expect(instance.valid?).to be false
        expect(instance.errors).to eq ['Druid column not found.']
      end
    end

    context 'with missing druid header not in a bulk job' do
      let(:csv) { 'title1:value,title2:value,title3:value' }
      let(:bulk_job) { false }

      it 'validates' do
        expect(instance.valid?).to be true
      end
    end

    context 'with headers that do not map to cocina model' do
      let(:csv) { 'druid,title1:value,title2:value,title3:value,bogus,event:contributor' }

      it 'finds errors' do
        expect(instance.valid?).to be false
        expect(instance.errors).to eq ['Column header invalid: bogus.']
      end
    end

    context 'with missing druid in a row' do
      let(:csv) do
        <<~CSV
          druid,title1:value,title2:value,title3:value
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
          druid,title1:value,title2:value,title3:value
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
end
