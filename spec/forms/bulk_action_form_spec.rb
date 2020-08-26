# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActionForm do
  let(:csv_file) { instance_double(File, path: nil) }
  let(:form) { described_class.new(BulkAction.new, groups: ['sdr:administrator-role']) }
  let(:params) do
    {
      import_tags: { csv_file: csv_file }
    }
  end

  describe '#csv_as_string' do
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
end
