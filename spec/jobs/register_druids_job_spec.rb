# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RegisterDruidsJob do
  include Dry::Monads[:result]

  subject(:job) { described_class.new(bulk_action.id, **params) }

  let(:params) { { csv_file: csv_string } }

  let(:bulk_action) { create(:bulk_action) }
  let(:response) { Success(cocina_object) }
  let(:log) { instance_double(File, puts: nil, close: true) }

  let(:catalog_link) do
    Cocina::Models::FolioCatalogLink.new(catalog: 'folio', catalogRecordId: 'in12345', refresh: true)
  end
  let(:identification) do
    Cocina::Models::Identification.new(barcode: '36105010101010', catalogLinks: [catalog_link], sourceId: 'foo:bar1')
  end

  let(:cocina_object) do
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
    allow_any_instance_of(BulkAction).to receive(:open_log_file).and_return(log) # rubocop:disable RSpec/AnyInstance
  end

  context 'when parsing fails' do
    let(:csv_string) do
      <<~CSV
        administrative_policy_object,initial_workflow,content_type,source_id,label,rights_view,rights_download
        druid:123,accessionWF,book,foo:123,My new object,world,world
      CSV
    end

    it 'does not register the object' do
      job.perform_now

      expect(RegistrationService).not_to have_received(:register)
      expect(log).to have_received(:puts).with(%r{string at `/administrative/hasAdminPolicy` does not match pattern:})
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
      job.perform_now

      expect(log).to have_received(:puts).with(/connection problem/)
      expect(bulk_action.druid_count_success).to eq 0
      expect(bulk_action.druid_count_fail).to eq 1
    end
  end

  context 'when registration is successful' do
    let(:csv_filepath) { "#{bulk_action.output_directory}/registration_report.csv" }

    it 'registers the object' do
      job.perform_now

      expect(RegistrationService).to have_received(:register).with(model: Cocina::Models::RequestDRO,
                                                                   tags: [
                                                                     'csv : test', 'Project : two'
                                                                   ],
                                                                   workflow: 'accessionWF')
      expect(RegistrationService).to have_received(:register).with(model: Cocina::Models::RequestDRO,
                                                                   tags: [],
                                                                   workflow: 'accessionWF')
      expect(log).to have_received(:puts).with(/Registration successful for druid:123/).twice
      expect(bulk_action.druid_count_success).to eq 2
      expect(File.read(csv_filepath)).to eq("Druid,Barcode,Folio Instance HRID,Source Id,Label\n123,36105010101010,in12345,foo:bar1,My object\n123,36105010101010,in12345,foo:bar1,My object\n")
    end
  end

  context 'when registration is successful with params' do
    # Params are provided from registration page (not bulk action page)
    let(:csv_string) do
      <<~CSV
        source_id,label
        foo:123,My new object
        foo:123,A label
      CSV
    end

    let(:params) do
      {
        csv_file: csv_string,
        administrative_policy_object: 'druid:bc123df4567',
        collection: 'druid:bk024qs1808',
        initial_workflow: 'accessionWF',
        content_type: 'book',
        rights_view: 'world',
        rights_download: 'world',
        tags: ['csv : test', 'Project : two']
      }
    end

    it 'registers the object' do
      job.perform_now

      expect(RegistrationService).to have_received(:register).with(model: Cocina::Models::RequestDRO,
                                                                   tags: [
                                                                     'csv : test', 'Project : two'
                                                                   ],
                                                                   workflow: 'accessionWF').twice
      expect(log).to have_received(:puts).with(/Registration successful for druid:123/).twice
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
      job.perform_now

      expect(RegistrationService).to have_received(:register).with(model: Cocina::Models::RequestDRO,
                                                                   tags: [
                                                                     'csv : test', 'Project : two'
                                                                   ],
                                                                   workflow: 'accessionWF')
      expect(RegistrationService).to have_received(:register).with(model: Cocina::Models::RequestDRO,
                                                                   tags: [],
                                                                   workflow: 'accessionWF')
      expect(log).to have_received(:puts).with(/Registration successful for druid:123/).twice
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
      job.perform_now

      expect(log).to have_received(:puts).with(%r{value at `/access/view` is not one of: \["dark"\]}).twice
      expect(bulk_action.druid_count_success).to eq 0
      expect(bulk_action.druid_count_fail).to eq 2
    end
  end
end
