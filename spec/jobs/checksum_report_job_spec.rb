# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChecksumReportJob, type: :job do
  let(:pids) { ['druid:123', 'druid:456'] }
  let(:groups) { [] }
  let(:user) { instance_double(User, to_s: 'jcoyne85') }
  let(:output_directory) { 'tmp/checksum_report_job_success' }
  let(:output_directory_fail) { 'tmp/checksum_report_job_fail' }
  # different output_directory so our 'fail' test doesn't inadvertently fail due to the CSV already existing from the 'success' test
  let(:bulk_action) do
    create(
      :bulk_action,
      action_type: 'ChecksumReportJob',
      log_name: 'tmp/checksum_report_job_log.txt'
    )
  end
  let(:csv_response) { "druid:123,checksum1,checksum2\ndruid:456,checksum3,checksum4\n" }
  let(:log_buffer) { StringIO.new }
  let(:my_conn) { instance_double(Faraday::Connection) }

  before do
    allow(subject).to receive(:bulk_action).and_return(bulk_action)
    allow(Ability).to receive(:new).and_return(ability)
    allow(Faraday).to receive(:new).and_return(my_conn)
  end

  describe '#perform_now' do
    context 'with authorization' do
      let(:ability) { instance_double(Ability, can?: true) }

      it 'calls the presevation_catalog API, writes a CSV file, and records success counts' do
        response = instance_double(Faraday::Response, success?: true, body: csv_response)
        allow(my_conn).to receive(:get).and_return(response)
        subject.perform(bulk_action.id,
                        output_directory: output_directory,
                        pids: pids,
                        groups: groups,
                        user: user)
        expect(my_conn).to have_received(:get).with('/objects/checksums', druids: pids, format: 'csv')
        expect(File).to exist(File.join(output_directory, Settings.checksum_report_job.csv_filename))
        expect(bulk_action.druid_count_total).to eq(pids.length)
        expect(bulk_action.druid_count_fail).to eq(0)
        expect(bulk_action.druid_count_success).to eq(pids.length)
      end
    end

    context 'without authorization' do
      let(:ability) { instance_double(Ability, can?: false) }

      it 'does not call the presevation_catalog API, does not write a CSV file, and records failure counts' do
        allow(my_conn).to receive(:get)
        subject.perform(bulk_action.id,
                        output_directory: output_directory_fail,
                        pids: pids,
                        groups: groups,
                        user: user)
        expect(my_conn).not_to have_received(:get).with('/objects/checksums', druids: pids, format: 'csv')
        expect(File).not_to exist(File.join(output_directory_fail, Settings.checksum_report_job.csv_filename))
        expect(bulk_action.druid_count_total).to eq(pids.length)
        expect(bulk_action.druid_count_fail).to eq(pids.length)
        expect(bulk_action.druid_count_success).to eq(0)
      end
    end
  end
end
