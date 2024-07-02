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

      context 'with mismatched structured title1.structuredValue columns' do
        let(:csv) { 'druid,title1.structuredValue1.type,title1.structuredValue1.value,title1.structuredValue12type,title1.structuredValue2.value' }

        it 'finds errors' do
          expect(instance.valid?).to be false
          expect(instance.errors).to eq [
            'Unexpected or missing title structuredValue columns: found title1.structuredValue2.value but not title1.structuredValue2.type'
          ]
        end
      end

      context 'with mismatched structured title2.structuredValue columns' do
        let(:csv) { 'druid,title1.structuredValue1.type,title1.structuredValue1.value,title2.structuredValue1.type,title2.structuredValue2.value' }

        it 'finds errors' do
          expect(instance.valid?).to be false
          expect(instance.errors).to eq [
            'Unexpected or missing title structuredValue columns: found title2.structuredValue1.type but not title2.structuredValue1.value',
            'Unexpected or missing title structuredValue columns: found title2.structuredValue2.value but not title2.structuredValue2.type'
          ]
        end
      end

      context 'with another form of mismatched structured title2.structuredValue columns' do
        let(:csv) { 'druid,title1.structuredValue1.type,title1.structuredValue1.value,title2.structuredValue2.type,title3.structuredValue2.value' }

        it 'finds errors' do
          expect(instance.valid?).to be false
          expect(instance.errors).to eq [
            'Unexpected or missing title structuredValue columns: found title2.structuredValue2.type but not title2.structuredValue2.value',
            'Unexpected or missing title structuredValue columns: found title3.structuredValue2.value but not title3.structuredValue2.type'
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

      context 'with missing title1.structuredValue1.value column' do
        let(:csv) { 'druid,title1.structuredValue1.type' }

        it 'finds errors' do
          expect(instance.valid?).to be false
          expect(instance.errors).to eq ['Title column not found.',
                                         'Unexpected or missing title structuredValue columns: found title1.structuredValue1.type but not title1.structuredValue1.value']
        end
      end

      context 'with missing title1.structuredValue1.type column' do
        let(:csv) { 'druid,title1.structuredValue1.value' }

        it 'finds errors' do
          expect(instance.valid?).to be false
          expect(instance.errors).to eq ['Title column not found.',
                                         'Unexpected or missing title structuredValue columns: found title1.structuredValue1.value but not title1.structuredValue1.type']
        end
      end

      context 'with a title1.structuredValue1.value and a title1.structuredValue1.type column' do
        let(:csv) { 'druid,title1.structuredValue1.type,title1.structuredValue1.value' }

        it 'validates' do
          expect(instance.valid?).to be true
        end
      end

      context 'with a title1.value,title2.structuredValue1.value and a title2.structuredValue1.type column' do
        let(:csv) { 'druid,title1.value,title2.structuredValue1.type,title2.structuredValue1.value' }

        it 'validates' do
          expect(instance.valid?).to be true
        end
      end

      context 'with the bulk_upload_descriptive fixture file' do
        let(:csv) { File.read('spec/fixtures/files/bulk_upload_descriptive.csv') }

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

      context 'with title1.parallelValue1.value column' do
        let(:csv) { 'druid,title1.parallelValue1.value' }

        it 'validates' do
          expect(instance.valid?).to be true
        end
      end

      context 'with title1.parallelValue1.structuredValue1.value column' do
        let(:csv) { 'druid,title1.parallelValue1.structuredValue1.value' }

        it 'validates' do
          expect(instance.valid?).to be true
        end
      end

      context 'with headers that do not map to cocina model' do
        let(:csv) do
          'druid,title1.value,title2.value,title3.value,bogus,event.contributor,event1.contributor,event1.note1.source.value'
        end

        it 'finds errors' do
          expect(instance.valid?).to be false
          # "bogus" is not a valid cocina attribute, and "event" must be an array (so needs to include a number)
          expect(instance.errors).to eq ['Column header invalid: bogus',
                                         'Column header invalid: event.contributor',
                                         'Column header invalid: event1.contributor']
        end
      end

      context 'with missing header for column' do
        let(:csv) { 'druid,title1.value,,title2.value' }

        it 'finds errors' do
          expect(instance.valid?).to be false
          # missing header value is not a valid cocina attribute
          expect(instance.errors).to eq ['Column header invalid: (empty string)']
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

      context 'with cell values that have a 0' do
        let(:csv) do
          <<~CSV
            druid,title1.value,title2.value
            druid:cd456de6677,allgood,stuff
            druid:cd456de6678,0,stuff
          CSV
        end

        it 'finds errors' do
          expect(instance.valid?).to be false
          expect(instance.errors).to eq ['Value error: druid:cd456de6678 has 0 value in title1.value.']
        end
      end

      context 'with cell values that look like formulas' do
        let(:csv) do
          <<~CSV
            druid,title1.value,title2.value
            druid:ab123cd4567,cool,#NA
            druid:cd456de5670,#REF!,stuff
            druid:cd456de8678,what,#VALUE?
            druid:cd456de6677,allgood,stuff
            druid:cd456de6678,#NAME?,stuff
          CSV
        end

        it 'finds errors' do
          expect(instance.valid?).to be false
          expect(instance.errors).to eq [
            'Value error: druid:ab123cd4567 has spreadsheet formula error in title2.value.',
            'Value error: druid:cd456de5670 has spreadsheet formula error in title1.value.',
            'Value error: druid:cd456de8678 has spreadsheet formula error in title2.value.',
            'Value error: druid:cd456de6678 has spreadsheet formula error in title1.value.'
          ]
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

      context 'with cell values that have a 0' do
        let(:csv) do
          <<~CSV
            title1.value,title2.value
            0,stuff
          CSV
        end

        it 'finds errors' do
          expect(instance.valid?).to be false
          expect(instance.errors).to eq ['Value error: row 2 has 0 value in title1.value.']
        end
      end

      context 'with cell values that look like formulas' do
        let(:csv) do
          <<~CSV
            title1.value,title2.value
            cool,#NA
          CSV
        end

        it 'finds errors' do
          expect(instance.valid?).to be false
          expect(instance.errors).to eq [
            'Value error: row 2 has spreadsheet formula error in title2.value.'
          ]
        end
      end
    end
  end
end
