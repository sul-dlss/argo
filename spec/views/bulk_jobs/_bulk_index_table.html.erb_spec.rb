# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'bulk_jobs/_bulk_index_table.html.erb' do
  let(:bulk_jobs) do
    [
      {}, # job log dir not found (status is 'not started')
      { # completed without errors
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
      { # completed with errors
        'argo.bulk_metadata.bulk_log_job_start' => '2016-04-21 10:34am',
        'argo.bulk_metadata.bulk_log_user' => 'tommyi',
        'argo.bulk_metadata.bulk_log_input_file' => 'crowdsourcing_bridget_2.xlsx',
        'argo.bulk_metadata.bulk_log_note' => 'convertonly',
        'argo.bulk_metadata.bulk_log_internal_error' => 'the server responded with status 500',
        'error' => 1,
        'argo.bulk_metadata.bulk_log_empty_response' => 'ERROR: No response from https://modsulator-app-stage.stanford.edu/v1/modsulator',
        'argo.bulk_metadata.bulk_log_error_exception' => 'Got no response from server',
        'argo.bulk_metadata.bulk_log_job_complete' => '2016-04-21 10:34am',
        'dir' => 'druid:bc682xk5613/2016_04_21_17_34_02_445',
        'argo.bulk_metadata.bulk_log_druids_loaded' => 0
      },
      { # in progress without errors
        'argo.bulk_metadata.bulk_log_job_start' => '2016-04-21 09:57am',
        'argo.bulk_metadata.bulk_log_user' => 'tommyi',
        'argo.bulk_metadata.bulk_log_input_file' => 'crowdsourcing_bridget_3.xlsx',
        'argo.bulk_metadata.bulk_log_xml_timestamp' => '2016-04-21 09:57am',
        'argo.bulk_metadata.bulk_log_xml_filename' => 'crowdsourcing_bridget_1-MODS.xml',
        'argo.bulk_metadata.bulk_log_record_count' => '20',
        'dir' => 'druid:bc682xk5613/2016_04_21_16_56_40_824',
        'argo.bulk_metadata.bulk_log_druids_loaded' => 0
      },
      { # in progress with errors
        'argo.bulk_metadata.bulk_log_job_start' => '2016-04-21 11:34am',
        'argo.bulk_metadata.bulk_log_user' => 'tommyi',
        'argo.bulk_metadata.bulk_log_input_file' => 'crowdsourcing_bridget_4.xlsx',
        'argo.bulk_metadata.bulk_log_note' => 'convertonly',
        'argo.bulk_metadata.bulk_log_internal_error' => 'the server responded with status 500',
        'error' => 1,
        'argo.bulk_metadata.bulk_log_empty_response' => 'ERROR: No response from https://modsulator-app-stage.stanford.edu/v1/modsulator',
        'argo.bulk_metadata.bulk_log_error_exception' => 'Got no response from server',
        'dir' => 'druid:bc682xk5613/2016_04_21_17_34_02_445',
        'argo.bulk_metadata.bulk_log_druids_loaded' => 0
      }
    ]
  end

  before do
    @document = double(id: '5')
    assign(:bulk_jobs, bulk_jobs)
    allow(view).to receive(:status_help_apo_bulk_jobs_path).and_return '/' # we get a missing id param error if we don't mock this
  end

  it 'has a delete button for each row with log info' do
    render
    expect(rendered).to have_css 'button[data-action="bulk-upload-jobs#openModal"]', text: 'Delete', count: 4
  end

  it 'has links to log info and XML for each row with log info' do
    render
    bulk_jobs[1..2].each do |job|
      druid_and_time = job['dir'].split %r{/}
      expect(rendered).to have_link 'Log', href: show_apo_bulk_jobs_path(druid_and_time[0], druid_and_time[1])
      expect(rendered).to have_link 'XML', href: show_apo_bulk_jobs_path(druid_and_time[0], druid_and_time[1], format: :xml)
    end
  end

  it 'prints error placeholders for each row with no log info' do
    render
    expect(rendered).to have_css 'table tr td', text: 'error:  job log dir not found', count: 3
    expect(rendered).to have_css 'table tr', text: 'error:  job log dir not found', count: 1
  end

  it 'shows the status' do
    render
    expect(rendered).to have_css 'table tr td', text: /\Anot started\z/, count: 1
    expect(rendered).to have_css 'table tr td', text: /\Acompleted\z/, count: 1
    expect(rendered).to have_css 'table tr td', text: /\Ain progress\z/, count: 1
    expect(rendered).to have_css 'table tr td', text: /\Acompleted [(]with system errors[)]\z/, count: 1
    expect(rendered).to have_css 'table tr td', text: /\Ain progress [(]with system errors[)]\z/, count: 1
  end
end
