require 'spec_helper'

RSpec.describe 'catalog/_bulk_index_table.html.erb' do
  let(:bulk_jobs) do
    [
      {},
      {
        'argo.bulk_metadata.bulk_log_job_start' => '2016-04-21 09:57am',
        'argo.bulk_metadata.bulk_log_user' => 'tommyi',
        'argo.bulk_metadata.bulk_log_input_file' => 'crowdsourcing_bridget_1.xlsx',
        'argo.bulk_metadata.bulk_log_xml_timestamp' => '2016-04-21 09:57am',
        'argo.bulk_metadata.bulk_log_xml_filename' => 'crowdsourcing_bridget_1-MODS.xml',
        'argo.bulk_metadata.bulk_log_record_count' => '20',
        'argo.bulk_metadata.bulk_log_job_complete' => '2016-04-21 09:57am',
        'dir' => 'druid:bc682xk5613/2016_04_21_16_56_40_824',
        'argo.bulk_metadata.bulk_log_druids_loaded' => 0
      },
      {
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
      }
    ]
  end

  before(:each) do
    assign(:bulk_jobs, bulk_jobs)
    allow(view).to receive(:bulk_status_help_path).and_return '/' # we get a missing id param error if we don't mock this
  end

  it 'has a delete button for each row with log info' do
    render
    expect(rendered).to have_css 'button.job-delete-button', text: 'Delete', count: 2
    bulk_jobs[1..2].each do |job|
      expect(rendered).to have_css 'button.job-delete-button', text: 'Delete'
      expect(rendered).to have_xpath "//button[@id='#{job['dir']}']", text: 'Delete' # id att has chars that cause problems in have_css call
    end
  end

  it 'has links to log info and XML for each row with log info' do
    render
    bulk_jobs[1..2].each do |job|
      druid_and_time = job['dir'].split %r(\/)
      expect(rendered).to have_link 'Log', href: bulk_jobs_log_path(druid_and_time[0], druid_and_time[1])
      expect(rendered).to have_link 'XML', href: bulk_jobs_xml_path(druid_and_time[0], druid_and_time[1])
    end
  end

  it 'prints error placeholders for each row with no log info' do
    render
    expect(rendered).to have_css 'div#bulk-upload-table table tr td', text: 'error:  job log dir not found', count: 3
    expect(rendered).to have_css 'div#bulk-upload-table table tr', text: 'error:  job log dir not found', count: 1
  end
end
