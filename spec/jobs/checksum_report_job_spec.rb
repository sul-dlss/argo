# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChecksumReportJob, type: :job do
  let(:druids) { ['druid:123', 'druid:456'] }
  let(:groups) { [] }
  let(:user) { instance_double(User, to_s: 'jcoyne85') }
  let(:output_directory) { bulk_action.output_directory }
  let(:bulk_action) do
    create(
      :bulk_action,
      action_type: 'ChecksumReportJob',
      log_name: 'tmp/checksum_report_job_log.txt'
    )
  end
  let(:csv_response) { "druid:123,checksum1,checksum2\ndruid:456,checksum3,checksum4\n" }
  let(:log_buffer) { StringIO.new }

  before do
    allow(subject).to receive(:bulk_action).and_return(bulk_action)
    allow(Ability).to receive(:new).and_return(ability)
  end

  after do
    FileUtils.rm_rf(output_directory) if Dir.exist?(output_directory)
  end

  describe '#perform_now' do
    context 'with authorization' do
      let(:ability) { instance_double(Ability, can?: true) }

      context 'happy path' do
        before do
          allow(Preservation::Client.objects).to receive(:checksums).with(druids:).and_return(csv_response)
        end

        it 'calls the presevation_catalog API, writes a CSV file, and records success counts' do
          subject.perform(bulk_action.id,
                          druids:,
                          groups:,
                          user:)
          expect(Preservation::Client.objects).to have_received(:checksums).with(druids:)
          expect(File).to exist(File.join(output_directory, Settings.checksum_report_job.csv_filename))
          expect(bulk_action.druid_count_total).to eq(druids.length)
          expect(bulk_action.druid_count_fail).to eq(0)
          expect(bulk_action.druid_count_success).to eq(druids.length)
        end
      end

      context 'Preservation::Client throws error' do
        before do
          allow(Preservation::Client.objects).to receive(:checksums).with(druids:).and_raise(Preservation::Client::UnexpectedResponseError, 'ruh roh')
          allow(Honeybadger).to receive(:context)
          allow(Honeybadger).to receive(:notify)
          allow(Rails.logger).to receive(:error)
        end

        it 'calls the presevation_catalog API, notifies honeybadger, logs an error, does not write a CSV file, and records failure counts' do
          exp_msg_regex = /ChecksumReportJob got error from Preservation Catalog API\ \(Preservation::Client::UnexpectedResponseError\): ruh roh/
          expect do
            subject.perform(bulk_action.id,
                            druids:,
                            groups:,
                            user:)
          end.not_to raise_error
          expect(Preservation::Client.objects).to have_received(:checksums).with(druids:)
          expect(File).not_to exist(File.join(output_directory, Settings.checksum_report_job.csv_filename))
          expect(Rails.logger).to have_received(:error).with(exp_msg_regex).once
          expect(Honeybadger).to have_received(:context).with(bulk_action_id: bulk_action.id, params: hash_including(druids:)).once
          expect(Honeybadger).to have_received(:notify).with(exp_msg_regex).once
          expect(bulk_action.druid_count_total).to eq(druids.length)
          expect(bulk_action.druid_count_fail).to eq(druids.length)
          expect(bulk_action.druid_count_success).to eq(0)
        end
      end
    end

    context 'without authorization' do
      let(:ability) { instance_double(Ability, can?: false) }

      before do
        allow(Preservation::Client.objects).to receive(:checksums)
        allow(Honeybadger).to receive(:context)
        allow(Honeybadger).to receive(:notify)
        allow(Rails.logger).to receive(:error)
      end

      it 'does not call the preservation_catalog API, notifies honeybadger, logs an error, does not write a CSV file, and records failure counts' do
        exp_msg_regex = /ChecksumReportJob not authorized to view all content/
        expect do
          subject.perform(bulk_action.id,
                          druids:,
                          groups:,
                          user:)
        end.not_to raise_error
        expect(Preservation::Client.objects).not_to have_received(:checksums)
        expect(File).not_to exist(File.join(output_directory, Settings.checksum_report_job.csv_filename))
        expect(Rails.logger).to have_received(:error).with(exp_msg_regex).once
        expect(Honeybadger).to have_received(:context).with(bulk_action_id: bulk_action.id, params: hash_including(druids:)).once
        expect(Honeybadger).to have_received(:notify).with(exp_msg_regex).once
        expect(bulk_action.druid_count_total).to eq(druids.length)
        expect(bulk_action.druid_count_fail).to eq(druids.length)
        expect(bulk_action.druid_count_success).to eq(0)
      end
    end
  end
end
