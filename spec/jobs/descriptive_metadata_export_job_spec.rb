# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DescriptiveMetadataExportJob do
  subject(:job) { described_class.new }

  let(:bulk_action) { create(:bulk_action, action_type: 'ExportTagsJob') }
  let(:csv_path) { File.join(bulk_action.output_directory, Settings.descriptive_metadata_export_job.csv_filename) }
  let(:log_buffer) { StringIO.new }
  let(:object_client1) { instance_double(Dor::Services::Client::Object, find: item1) }
  let(:object_client2) { instance_double(Dor::Services::Client::Object, find: item2) }

  before do
    allow(job).to receive(:bulk_action).and_return(bulk_action)
    allow(job).to receive(:with_bulk_action_log).and_yield(log_buffer)
    allow(Dor::Services::Client).to receive(:object).with(druid1).and_return(object_client1)
    allow(Dor::Services::Client).to receive(:object).with(druid2).and_return(object_client2)
  end

  after do
    FileUtils.rm_f(csv_path)
  end

  describe '#perform_now' do
    let(:druids) { [druid1, druid2, druid3] }
    let(:druid1) { 'druid:bc123df4567' }
    let(:druid2) { 'druid:bd123fg5678' }
    let(:druid3) { 'druid:bf123fg5678' }
    let(:groups) { [] }
    let(:user) { instance_double(User, to_s: 'jcoyne85') }
    let(:item1) do
      build(:dro_with_metadata, id: druid1, source_id: 'sul:4444')
    end
    let(:item2) do
      build(:dro_with_metadata, id: druid2, title: 'Test DRO #2')
    end

    context 'when happy path' do
      let(:response) { instance_double(Faraday::Response, status: 500, body: nil, reason_phrase: 'Something went wrong') }

      before do
        allow(Dor::Services::Client).to receive(:object).with(druid3).and_raise(Dor::Services::Client::UnexpectedResponse.new(response:))
        job.perform(bulk_action.id, druids:, groups:, user:)
      end

      it 'writes a CSV file' do
        csv = CSV.read(csv_path, headers: true)
        expect(csv.headers).to eq ['druid', 'source_id', 'title1.value', 'purl']
        expect(csv[0][0]).to eq(druid1)
        expect(csv[1][0]).to eq(druid2)
        expect(csv[0][1]).to eq 'sul:4444'
        expect(csv[1][1]).to eq 'sul:1234'
        expect(csv[1]['title1.value']).to eq 'Test DRO #2'
      end

      it 'tracks success/failure' do
        expect(bulk_action.druid_count_success).to eq 2
        expect(bulk_action.druid_count_fail).to eq 1
        expect(bulk_action.druid_count_total).to eq 3
      end
    end

    context 'when APO included among druids' do
      let(:item3) { build(:admin_policy_with_metadata, id: druid3) }
      let(:object_client3) { instance_double(Dor::Services::Client::Object, find: item3) }

      before do
        allow(Dor::Services::Client).to receive(:object).with(druid3).and_return(object_client3)
        allow(log_buffer).to receive(:puts)
        job.perform(bulk_action.id, druids:, groups:, user:)
      end

      it 'tracks success/failure' do
        expect(bulk_action.druid_count_success).to eq(2)
        expect(bulk_action.druid_count_fail).to eq(1)
        expect(bulk_action.druid_count_total).to eq(3)
      end

      it 'logs error messages' do
        expect(log_buffer).to have_received(:puts).with(/Failed NoMethodError .+ for #{druid3}/).once
      end
    end

    context 'when missing druid is included' do
      let(:response) { instance_double(Faraday::Response, status: 404, body: nil, reason_phrase: "Couldn't find object with 'external_identifier'=#{druid3}") }

      before do
        allow(Dor::Services::Client).to receive(:object).with(druid3).and_raise(Dor::Services::Client::NotFoundResponse.new(response:))
        allow(log_buffer).to receive(:puts)
        job.perform(bulk_action.id, druids:, groups:, user:)
      end

      it 'tracks success/failure' do
        expect(bulk_action.druid_count_success).to eq(2)
        expect(bulk_action.druid_count_fail).to eq(1)
        expect(bulk_action.druid_count_total).to eq(3)
      end

      it 'logs error messages' do
        expect(log_buffer).to have_received(:puts).with(/Could not find object identified by druid '#{druid3}'/).once
      end
    end

    context 'when malformed druid is included' do
      let(:response) { instance_double(Faraday::Response, status: 400, body: nil, reason_phrase: "#/components/schemas/Druid pattern ^druid:[b-df-hjkmnp-tv-z]{2}[0-9]{3}[b-df-hjkmnp-tv-z]{2}[0-9]{4}$ does not match value: \"#{druid3}\", example: druid:bc123df4567") }

      before do
        allow(Dor::Services::Client).to receive(:object).with(druid3).and_raise(Dor::Services::Client::BadRequestError.new(response:))
        allow(log_buffer).to receive(:puts)
        job.perform(bulk_action.id, druids:, groups:, user:)
      end

      it 'tracks success/failure' do
        expect(bulk_action.druid_count_success).to eq(2)
        expect(bulk_action.druid_count_fail).to eq(1)
        expect(bulk_action.druid_count_total).to eq(3)
      end

      it 'logs error messages' do
        expect(log_buffer).to have_received(:puts).with(/Could not request object identified by druid '#{druid3}'. Possibly malformed druid?/).once
      end
    end
  end
end
