# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RegisterDruidsJob, type: :job do
  include Dry::Monads[:result]

  subject(:job) { described_class.new }

  let(:bulk_action) { create(:bulk_action) }
  let(:response) { Success(model) }
  let(:fake_log) { double('logger', puts: nil) }
  let(:identification) do
    instance_double(Cocina::Models::Identification, sourceId: 'foo:bar1')
  end

  let(:model) do
    instance_double(Cocina::Models::DROWithMetadata,
                    externalIdentifier: 'druid:123',
                    label: 'My object',
                    identification:)
  end

  let(:csv_string) do
    <<~CSV
      administrative_policy_object,collection,initial_workflow,content_type,source_id,label,rights_view,rights_download,tags,tags
      druid:bc123df4567,druid:bk024qs1808,accessionWF,book,foo:123,My new object,world,world,csv : test,Project : two
      druid:dj123qx4567,druid:bk024qs1808,accessionWF,book,foo:123,A label,world,world
    CSV
  end

  before do
    allow(BulkAction).to receive(:find).and_return(bulk_action)
    allow(RegistrationService).to receive(:register).and_return(response)
    allow(BulkJobLog).to receive(:open).and_yield(fake_log)
    job.perform(bulk_action.id, csv_file: csv_string)
  end

  describe '#perform' do
    context 'when parsing fails' do
      let(:csv_string) do
        <<~CSV
          administrative_policy_object,initial_workflow,content_type,source_id,label,rights_view,rights_download
          druid:123,accessionWF,book,foo:123,My new object,world,world
        CSV
      end

      it 'does not register the object' do
        expect(RegistrationService).not_to have_received(:register)
        expect(fake_log).to have_received(:puts).with(/does not match value: "druid:123", example: druid:bc123df4567/)
        expect(bulk_action.druid_count_success).to eq 0
        expect(bulk_action.druid_count_fail).to eq 1
      end
    end

    context 'when registration fails' do
      let(:response) { Failure(RuntimeError.new('connection problem')) }
      let(:csv_string) do
        <<~CSV
          administrative_policy_object,initial_workflow,content_type,source_id,label,rights_view,rights_download,tags,tags
          druid:bc123df4567,accessionWF,book,foo:123,My new object,world,world,csv : test,Project : two
        CSV
      end

      it 'logs the error' do
        expect(fake_log).to have_received(:puts).with(/connection problem/)
        expect(bulk_action.druid_count_success).to eq 0
        expect(bulk_action.druid_count_fail).to eq 1
      end
    end

    context 'when registration is successful' do
      it 'registers the object' do
        expect(RegistrationService).to have_received(:register).with(model: Cocina::Models::RequestDRO,
                                                                     tags: ['csv : test', 'Project : two'],
                                                                     workflow: 'accessionWF')
        expect(RegistrationService).to have_received(:register).with(model: Cocina::Models::RequestDRO,
                                                                     tags: [],
                                                                     workflow: 'accessionWF')
        expect(fake_log).to have_received(:puts).with(/Successfully registered druid:123/).twice
        expect(bulk_action.druid_count_success).to eq 2
      end
    end

    context 'with valid view:stanford, download:none, and rights_controlledDigitalLending:true' do
      let(:csv_string) do
        <<~CSV
          administrative_policy_object,collection,initial_workflow,content_type,source_id,label,rights_view,rights_download,rights_controlledDigitalLending,tags,tags
          druid:bc123df4567,druid:bk024qs1808,accessionWF,book,foo:123,My new object,stanford,none,true,csv : test,Project : two
          druid:dj123qx4567,druid:bk024qs1808,accessionWF,book,foo:123,A label,stanford,none,true
        CSV
      end

      it 'registers the objects' do
        expect(RegistrationService).to have_received(:register).with(model: Cocina::Models::RequestDRO,
                                                                     tags: ['csv : test', 'Project : two'],
                                                                     workflow: 'accessionWF')
        expect(RegistrationService).to have_received(:register).with(model: Cocina::Models::RequestDRO,
                                                                     tags: [],
                                                                     workflow: 'accessionWF')
        expect(fake_log).to have_received(:puts).with(/Successfully registered druid:123/).twice
        expect(bulk_action.druid_count_success).to eq 2
      end
    end

    context 'with invalid view:world, download:none, and rights_controlledDigitalLending:true' do
      let(:csv_string) do
        <<~CSV
          administrative_policy_object,collection,initial_workflow,content_type,source_id,label,rights_view,rights_download,rights_controlledDigitalLending,tags,tags
          druid:bc123df4567,druid:bk024qs1808,accessionWF,book,foo:123,My new object,world,none,true,csv : test,Project : two
          druid:dj123qx4567,druid:bk024qs1808,accessionWF,book,foo:123,A label,world,none,true
        CSV
      end

      it 'does not register the objects' do
        expect(fake_log).to have_received(:puts).with(%r{isn't one of in \#/components/schemas/Access}).twice
        expect(bulk_action.druid_count_success).to eq 0
        expect(bulk_action.druid_count_fail).to eq 2
      end
    end
  end
end
