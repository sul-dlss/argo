# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChecksumReportJob do
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
  let(:checksum_response) do
    [{
      'filename' => 'oo000oo0000_img_1.tif',
      'md5' => 'ffc0cc90e4215e0a3d822b04a8eab980',
      'sha1' => 'd2703add746d7b6e2e5f8a73ef7c06b087b3fae5',
      'sha256' => '6b66cc2df50427d03dca8608af20b3fd96d76b67ba41c148901aa1a60527032f',
      'filesize' => '4403882'
    },
     {
       'filename' => 'oo000oo0000_img_2.tif',
       'md5' => 'ggc0cc90e4215e0a3d822b04a8eab991',
       'sha1' => 'e3703add746d7b6e2e5f8a73ef7c06b087b3faf6',
       'sha256' => '7c66cc2df50427d03dca8608af20b3fd96d76b67ba41c148901aa1a60527033g',
       'filesize' => '5503893'
     }]
  end

  before do
    allow(subject).to receive(:bulk_action).and_return(bulk_action)
    allow(Ability).to receive(:new).and_return(ability)
  end

  after do
    FileUtils.rm_rf(output_directory)
  end

  describe '#perform_now' do
    context 'with authorization' do
      let(:ability) { instance_double(Ability, can?: true) }

      context 'when happy path' do
        before do
          allow(Preservation::Client.objects).to receive(:checksum).with(druid: druids[0]).and_return(checksum_response)
          allow(Preservation::Client.objects).to receive(:checksum).with(druid: druids[1]).and_raise(Preservation::Client::NotFoundError)
        end

        it 'calls the presevation_catalog API, writes a CSV file, and records success counts' do
          subject.perform(bulk_action.id,
                          druids:,
                          groups:,
                          user:)
          expect(File.read(File.join(output_directory, Settings.checksum_report_job.csv_filename))).to eq(
            <<~CSV
              druid:123,oo000oo0000_img_1.tif,ffc0cc90e4215e0a3d822b04a8eab980,d2703add746d7b6e2e5f8a73ef7c06b087b3fae5,6b66cc2df50427d03dca8608af20b3fd96d76b67ba41c148901aa1a60527032f,4403882
              druid:123,oo000oo0000_img_2.tif,ggc0cc90e4215e0a3d822b04a8eab991,e3703add746d7b6e2e5f8a73ef7c06b087b3faf6,7c66cc2df50427d03dca8608af20b3fd96d76b67ba41c148901aa1a60527033g,5503893
              druid:456,object not found or not fully accessioned
            CSV
          )
          expect(bulk_action.druid_count_total).to eq(2)
          expect(bulk_action.druid_count_fail).to eq(1)
          expect(bulk_action.druid_count_success).to eq(1)
        end
      end

      context 'when Preservation::Client throws error' do
        before do
          allow(Preservation::Client.objects).to receive(:checksum).and_raise(
            Preservation::Client::UnexpectedResponseError, 'ruh roh'
          )
        end

        it 'calls the presevation_catalog API, does not write a CSV file, and records failure counts' do
          subject.perform(bulk_action.id, druids:, groups:, user:)

          expect(Preservation::Client.objects).to have_received(:checksum).with(druid: druids.first)
          expect(bulk_action.druid_count_total).to eq(druids.length)
          expect(bulk_action.druid_count_fail).to eq(druids.length)
          expect(bulk_action.druid_count_success).to eq(0)
        end
      end
    end

    context 'without authorization' do
      let(:ability) { instance_double(Ability, can?: false) }

      before do
        allow(Preservation::Client.objects).to receive(:checksum)
      end

      it 'does not call the preservation_catalog API and records failure counts' do
        subject.perform(bulk_action.id, druids:, groups:, user:)
        expect(Preservation::Client.objects).not_to have_received(:checksum)
        expect(bulk_action.druid_count_total).to eq(druids.length)
        expect(bulk_action.druid_count_fail).to eq(druids.length)
        expect(bulk_action.druid_count_success).to eq(0)
      end
    end
  end
end
