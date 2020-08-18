# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RegisterDruidsJob, type: :job do
  include Dry::Monads[:result]

  subject(:job) { described_class.new }

  let(:bulk_action) { create(:bulk_action) }
  let(:response) { Success(model) }
  let(:model) { instance_double(Cocina::Models::DRO, externalIdentifier: 'druid:123') }
  let(:fake_log) { double('logger', puts: nil) }
  let(:csv_string) do
    <<~CSV
      APO,Rights,Initial Workflow,Content Type,Source ID,Label,Tags,Tags
      druid:bc123df4567,world,accessionWF,book,foo:123,My new object,csv : test,Project : two
      druid:dj123qx4567,world,accessionWF,book,foo:123,A label
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
          APO,Rights,Initial Workflow,Content Type,Source ID,Label
          druid:123,world,accessionWF,book,foo:123,My new object
        CSV
      end

      it 'registers the object' do
        expect(RegistrationService).not_to have_received(:register)
        expect(fake_log).to have_received(:puts).with(/does not match value: druid:123, example: druid:bc123df4567/)
        expect(bulk_action.druid_count_success).to eq 0
        expect(bulk_action.druid_count_fail).to eq 1
      end
    end

    context 'when registration fails' do
      let(:response) { Failure('connection problem') }
      let(:csv_string) do
        <<~CSV
          APO,Rights,Initial Workflow,Content Type,Source ID,Label,Tags,Tags
          druid:bc123df4567,world,accessionWF,book,foo:123,My new object,csv : test,Project : two
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
  end
end
