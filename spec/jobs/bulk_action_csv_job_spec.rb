# frozen_string_literal: true

require 'rails_helper'

DRUID1 = 'druid:bb111cc2222'
DRUID2 = 'druid:cc111dd2222'

RSpec.describe BulkActionCsvJob do
  # Setting count fields to ensure that they are reset.
  let(:bulk_action) { create(:bulk_action, druid_count_success: 100, druid_count_fail: 100, druid_count_total: 100) }

  let(:log) { instance_double(File, puts: nil, close: true) }
  let(:export_file) { instance_double(File, close: true) }

  before do
    bulk_action_job_class = Class.new(described_class)
    stub_const('TestBulkActionCsvJob', bulk_action_job_class)

    bulk_action_item_class = Class.new(BulkActionCsvJobItem) do
      def perform
        success!(message: 'Testing successful') if druid == DRUID1
        failure!(message: 'Testing failed') if druid == DRUID2
      end
    end
    stub_const('TestBulkActionCsvJob::TestBulkActionCsvJobItem', bulk_action_item_class)

    allow(TestBulkActionCsvJob::TestBulkActionCsvJobItem).to receive(:new).and_call_original

    allow_any_instance_of(BulkAction).to receive(:open_log_file).and_return(log) # rubocop:disable RSpec/AnyInstance
  end

  after do
    FileUtils.rm_rf(bulk_action.output_directory)
  end

  context 'when no errors' do
    let(:csv_file) do
      [
        'druid,test',
        [DRUID1, 'test1'].join(','),
        [DRUID2, 'test2'].join(',')
      ].join("\n")
    end

    let(:csv) { CSV.parse(csv_file, headers: true) }

    it 'performs the job' do
      TestBulkActionCsvJob.perform_now(bulk_action.id, csv_file: csv_file)

      expect(TestBulkActionCsvJob::TestBulkActionCsvJobItem).to have_received(:new).with(druid: DRUID1, row: csv[0], index: 2, job: instance_of(TestBulkActionCsvJob))
      expect(TestBulkActionCsvJob::TestBulkActionCsvJobItem).to have_received(:new).with(druid: DRUID2, row: csv[1], index: 3, job: instance_of(TestBulkActionCsvJob))

      expect(log).to have_received(:puts).with(/Starting TestBulkActionCsvJob for BulkAction #{bulk_action.id}/)
      expect(log).to have_received(:puts).with(/Finished TestBulkActionCsvJob for BulkAction #{bulk_action.id}/)
      expect(log).to have_received(:puts).with(/line 2 - Testing successful for #{DRUID1}/o)
      expect(log).to have_received(:puts).with(/line 3 - Testing failed for #{DRUID2}/o)

      expect(bulk_action.reload.druid_count_total).to eq(2)
      expect(bulk_action.druid_count_success).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(1)
      expect(bulk_action.status).to eq('Completed')
    end
  end

  context 'when CSV missing druid column' do
    let(:csv_file) do
      [
        'id,test',
        ['druid:bb111cc2222', 'test1'].join(','),
        ['druid:cc111dd2222', 'test2'].join(',')
      ].join("\n")
    end

    it 'does not processes the druids' do
      TestBulkActionCsvJob.perform_now(bulk_action.id, csv_file: csv_file)

      expect(TestBulkActionCsvJob::TestBulkActionCsvJobItem).not_to have_received(:new)

      expect(log).to have_received(:puts).with(/Column "druid" not found/)

      expect(bulk_action.reload.druid_count_total).to eq(2)
      expect(bulk_action.druid_count_fail).to eq(2)
    end
  end
end
