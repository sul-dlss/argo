# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CsvRegistrationForm do
  let(:form) { described_class.new(nil) }

  describe 'CSV file validation' do
    let(:csv_file) { ActionDispatch::Http::UploadedFile.new(tempfile: File.open(csv_fixture)) }

    before do
      form.validate({ csv_file: })
    end

    context 'when "one of" headers are missing' do
      let(:csv_fixture) { file_fixture('catalog_record_id_and_barcode.csv') }

      it 'is not valid' do
        expect(form).not_to be_valid
      end

      it 'returns errors' do
        expect(form.errors.full_messages).to include(
          /is missing a title \(each row needs a value in title or folio_instance_hrid\)/
        )
      end
    end

    context 'when the CSV has a label column instead of a title column' do
      let(:csv_fixture) { file_fixture('item_registration_label.csv') }

      it 'is not valid' do
        expect(form).not_to be_valid
      end

      it 'returns errors calling out the label column' do
        expect(form.errors.full_messages).to include(
          /has a "label" column, which is not valid \(titles must be in a column named "title"\)/
        )
      end
    end

    context 'when not all rows have "one of" data exist' do
      let(:csv_fixture) { file_fixture('item_registration_incomplete.csv') }

      it 'is not valid' do
        expect(form).not_to be_valid
      end

      it 'returns errors' do
        expect(form.errors.full_messages).to include(
          /is missing a title \(each row needs a value in title or folio_instance_hrid\)/
        )
      end
    end

    context 'when happy path' do
      let(:csv_fixture) { file_fixture('item_registration.csv') }

      it 'is valid' do
        expect(form).to be_valid
      end

      it 'returns no errors' do
        expect(form.errors).to be_empty
      end
    end
  end
end
