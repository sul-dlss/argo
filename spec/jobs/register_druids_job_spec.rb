# frozen_string_literal: true

require "rails_helper"

RSpec.describe RegisterDruidsJob do
  include Dry::Monads[:result]

  subject(:job) { described_class.new }

  let(:bulk_action) { create(:bulk_action) }
  let(:response) { Success(model) }
  let(:fake_log) { double("logger", puts: nil) }
  let(:catalog_link) do
    instance_double(Cocina::Models::FolioCatalogLink, catalog: "folio", catalogRecordId: "in12345", refresh: true)
  end
  let(:identification) do
    instance_double(Cocina::Models::Identification, barcode: "12345", catalogLinks: [catalog_link], sourceId: "foo:bar1")
  end

  let(:model) do
    instance_double(Cocina::Models::DROWithMetadata,
      externalIdentifier: "druid:123",
      label: "My object",
      identification:)
  end

  let(:csv_string) do
    <<~CSV
      administrative_policy_object,collection,initial_workflow,content_type,source_id,label,rights_view,rights_download,tags,tags
      druid:bc123df4567,druid:bk024qs1808,accessionWF,book,foo:123,My new object,world,world,csv : test,Project : two
      druid:dj123qx4567,druid:bk024qs1808,accessionWF,book,foo:123,A label,world,world
    CSV
  end

  let(:params) { {csv_file: csv_string} }

  before do
    allow(BulkAction).to receive(:find).and_return(bulk_action)
    allow(RegistrationService).to receive(:register).and_return(response)
    allow(BulkJobLog).to receive(:open).and_yield(fake_log)
    job.perform(bulk_action.id, **params)
  end

  describe "#perform" do
    context "when parsing fails" do
      let(:csv_string) do
        <<~CSV
          administrative_policy_object,initial_workflow,content_type,source_id,label,rights_view,rights_download
          druid:123,accessionWF,book,foo:123,My new object,world,world
        CSV
      end

      it "does not register the object" do
        expect(RegistrationService).not_to have_received(:register)
        expect(fake_log).to have_received(:puts).with(/does not match value: "druid:123", example: druid:bc123df4567/)
        expect(bulk_action.druid_count_success).to eq 0
        expect(bulk_action.druid_count_fail).to eq 1
      end
    end

    context "when registration fails" do
      let(:response) { Failure(RuntimeError.new("connection problem")) }
      let(:csv_string) do
        <<~CSV
          administrative_policy_object,initial_workflow,content_type,source_id,label,rights_view,rights_download,tags,tags
          druid:bc123df4567,accessionWF,book,foo:123,My new object,world,world,csv : test,Project : two
        CSV
      end

      it "logs the error" do
        expect(fake_log).to have_received(:puts).with(/connection problem/)
        expect(bulk_action.druid_count_success).to eq 0
        expect(bulk_action.druid_count_fail).to eq 1
      end
    end

    context "when registration is successful" do
      let(:csv_filepath) { "#{Settings.bulk_metadata.directory}RemoteIndexingJob_1/registration_report.csv" }

      it "registers the object" do
        expect(RegistrationService).to have_received(:register).with(model: Cocina::Models::RequestDRO,
          tags: ["csv : test", "Project : two"],
          workflow: "accessionWF")
        expect(RegistrationService).to have_received(:register).with(model: Cocina::Models::RequestDRO,
          tags: [],
          workflow: "accessionWF")
        expect(fake_log).to have_received(:puts).with(/Successfully registered druid:123/).twice
        expect(bulk_action.druid_count_success).to eq 2
        expect(File.read(csv_filepath)).to eq("Druid,Barcode,Folio Instance HRID,Source Id,Label\n123,12345,in12345,foo:bar1,My object\n123,12345,in12345,foo:bar1,My object\n")
      end
    end

    context "when registration is successful with params" do
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
          administrative_policy_object: "druid:bc123df4567",
          collection: "druid:bk024qs1808",
          initial_workflow: "accessionWF",
          content_type: "book",
          rights_view: "world",
          rights_download: "world",
          tags: ["csv : test", "Project : two"]
        }
      end

      it "registers the object" do
        expect(RegistrationService).to have_received(:register).with(model: Cocina::Models::RequestDRO,
          tags: ["csv : test", "Project : two"],
          workflow: "accessionWF").twice
        expect(fake_log).to have_received(:puts).with(/Successfully registered druid:123/).twice
        expect(bulk_action.druid_count_success).to eq 2
      end
    end

    context "with valid view:stanford, download:none, and rights_controlledDigitalLending:true" do
      let(:csv_string) do
        <<~CSV
          administrative_policy_object,collection,initial_workflow,content_type,source_id,label,rights_view,rights_download,rights_controlledDigitalLending,tags,tags
          druid:bc123df4567,druid:bk024qs1808,accessionWF,book,foo:123,My new object,stanford,none,true,csv : test,Project : two
          druid:dj123qx4567,druid:bk024qs1808,accessionWF,book,foo:123,A label,stanford,none,true
        CSV
      end

      it "registers the objects" do
        expect(RegistrationService).to have_received(:register).with(model: Cocina::Models::RequestDRO,
          tags: ["csv : test", "Project : two"],
          workflow: "accessionWF")
        expect(RegistrationService).to have_received(:register).with(model: Cocina::Models::RequestDRO,
          tags: [],
          workflow: "accessionWF")
        expect(fake_log).to have_received(:puts).with(/Successfully registered druid:123/).twice
        expect(bulk_action.druid_count_success).to eq 2
      end
    end

    context "with invalid view:world, download:none, and rights_controlledDigitalLending:true" do
      let(:csv_string) do
        <<~CSV
          administrative_policy_object,collection,initial_workflow,content_type,source_id,label,rights_view,rights_download,rights_controlledDigitalLending,tags,tags
          druid:bc123df4567,druid:bk024qs1808,accessionWF,book,foo:123,My new object,world,none,true,csv : test,Project : two
          druid:dj123qx4567,druid:bk024qs1808,accessionWF,book,foo:123,A label,world,none,true
        CSV
      end

      it "does not register the objects" do
        expect(fake_log).to have_received(:puts).with(%r{isn't one of in \#/components/schemas/Access}).twice
        expect(bulk_action.druid_count_success).to eq 0
        expect(bulk_action.druid_count_fail).to eq 2
      end
    end
  end
end
