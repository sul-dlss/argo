# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActionForm do
  let(:form) { described_class.new(BulkAction.new, groups: ['sdr:administrator-role']) }

  describe '#csv_as_string' do
    let(:csv_file) { instance_double(File, path: nil) }
    let(:params) do
      {
        import_tags: { csv_file: csv_file }
      }
    end

    before do
      allow(File).to receive(:read)
      allow(BulkActionPersister).to receive(:persist)
    end

    it 'works in import_tags context' do
      form.validate(params)
      form.save
      form.csv_as_string
      expect(File).to have_received(:read).once
      expect(BulkActionPersister).to have_received(:persist).once
    end
  end

  describe '#license_options' do
    let(:params) do
      {
        set_license_and_rights_statements: {
          copyright_statement_option: '1',
          copyright_statement: 'a new statement'
        }
      }
    end

    before do
      allow(BulkActionPersister).to receive(:persist)
    end

    it 'validates, saves, and persists' do
      form.validate(params)
      form.save
      # A subset of licenses from Constants::LICENSE_OPTIONS
      expect(form.license_options).to include(
        ['-- No license --', ''],
        ['CC Attribution 4.0 International', 'https://creativecommons.org/licenses/by/4.0/legalcode'],
        ['CC Attribution-NonCommercial 4.0 International', 'https://creativecommons.org/licenses/by-nc/4.0/legalcode']
      )
      expect(BulkActionPersister).to have_received(:persist).once
    end
  end
end
