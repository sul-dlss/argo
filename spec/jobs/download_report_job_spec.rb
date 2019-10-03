# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DownloadReportJob, type: :job do
  let(:search_params) { { f: { exploded_tag_ssim: [] } }.with_indifferent_access }
  let(:selected_columns) { ['Druid', 'Title'] }
  let(:groups) { [] }
  let(:report) { instance_double(Report) }
  let(:output_directory) { 'tmp/download_report_job_success' }
  let(:bulk_action) do
    create(
      :bulk_action,
      action_type: 'DownloadReportJob',
      log_name: 'tmp/download_report_job_log.txt'
    )
  end
  let(:csv_response) { "Druid,Title\ndruid:123,Title\n\ndruid:345,Title2\n" }
  let(:log_buffer) { StringIO.new }

  before do
    allow(subject).to receive(:bulk_action).and_return(bulk_action)
    allow(Report).to receive(:new).with(search_params, selected_columns, current_user: bulk_action.user).and_return(report)
    allow(report).to receive(:num_found).and_return(5)
    allow(report).to receive(:to_csv).and_return(csv_response)
  end

  describe '#perform_now' do
    it 'downloads a report' do
      subject.perform(bulk_action.id,
                      output_directory: output_directory,
                      download_report: { search_params: search_params.to_json, selected_columns: selected_columns },
                      groups: groups)
      expect(File).to exist(File.join(output_directory, Settings.download_report_job.csv_filename))
    end
  end
end
