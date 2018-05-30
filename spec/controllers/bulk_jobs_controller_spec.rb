require 'spec_helper'

RSpec.describe BulkJobsController do
  describe '#show' do
    # These parameters correspond to the directory:
    #   spec/fixtures/bulk_upload/workspace/druid:bc682xk5613/2016_04_21_16_56_40_824/
    let(:apo_id) { 'druid:bc682xk5613' }
    let(:time) { '2016_04_21_16_56_40_824' }
    let(:user) { create(:user) }

    before do
      sign_in user
    end

    context 'when the format is html' do
      it 'is successful' do
        get :show, params: { apo_id: apo_id, time: time }
        expect(response).to be_successful
        expect(assigns[:apo]).to eq apo_id
        expect(assigns[:time]).to eq '2016_04_21_16_56_40_824'
        expect(assigns[:druid_log]).to be_kind_of Array
      end
    end

    context 'when the format is xml' do
      it 'is successful' do
        get :show, params: { apo_id: apo_id, time: time, format: 'xml' }
        expect(response).to be_successful
      end
    end

    context 'when the format is csv' do
      it 'is successful' do
        get :show, params: { apo_id: apo_id, time: time, format: 'csv' }
        expect(response).to be_successful
      end
    end
  end

  describe '#load_bulk_jobs' do
    let(:sorted_bulk_job_info) { controller.send(:load_bulk_jobs, 'druid:bc682xk5613') }
    it 'loads the expected number of records' do
      expect(sorted_bulk_job_info.length).to eq 5
    end

    it 'loads an empty record for a job with a missing log file (and the record should sort to the end)' do
      expect(sorted_bulk_job_info.last).to be_empty
    end

    it 'loads the expected information when a log file is present' do
      # spot check a couple known records
      expect(sorted_bulk_job_info[3]).to include(
        'argo.bulk_metadata.bulk_log_job_start' => '2016-04-21 09:57am',
        'argo.bulk_metadata.bulk_log_user' => 'tommyi',
        'argo.bulk_metadata.bulk_log_input_file' => 'crowdsourcing_bridget_1.xlsx',
        'argo.bulk_metadata.bulk_log_xml_timestamp' => '2016-04-21 09:57am',
        'argo.bulk_metadata.bulk_log_xml_filename' => 'crowdsourcing_bridget_1-MODS.xml',
        'argo.bulk_metadata.bulk_log_record_count' => '20',
        'argo.bulk_metadata.bulk_log_job_complete' => '2016-04-21 09:57am',
        'dir' => 'druid:bc682xk5613/2016_04_21_16_56_40_824',
        'argo.bulk_metadata.bulk_log_druids_loaded' => 0
      )
      expect(sorted_bulk_job_info[0]).to include(
        'argo.bulk_metadata.bulk_log_job_start' => '2016-04-21 10:34am',
        'argo.bulk_metadata.bulk_log_user' => 'tommyi',
        'argo.bulk_metadata.bulk_log_input_file' => 'crowdsourcing_bridget_1.xlsx',
        'argo.bulk_metadata.bulk_log_note' => 'convertonly',
        'argo.bulk_metadata.bulk_log_internal_error' => 'the server responded with status 500',
        'error' => 1,
        'argo.bulk_metadata.bulk_log_empty_response' => 'ERROR: No response from https://modsulator-app-stage.stanford.edu/v1/modsulator',
        'argo.bulk_metadata.bulk_log_error_exception' => 'Got no response from server',
        'argo.bulk_metadata.bulk_log_job_complete' => '2016-04-21 10:34am',
        'dir' => 'druid:bc682xk5613/2016_04_21_17_34_02_445',
        'argo.bulk_metadata.bulk_log_druids_loaded' => 0
      )
    end
  end
end
