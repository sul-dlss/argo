# frozen_string_literal: true

require "rails_helper"

RSpec.describe ItemChangeSetPersister do
  describe ".update" do
    let(:change_set) { instance_double(ItemChangeSet) }
    let(:instance) { instance_double(described_class, update: nil) }
    let(:model) { instance_double(Cocina::Models::DROWithMetadata) }

    before do
      allow(described_class).to receive(:new).and_return(instance)
      described_class.update(model, change_set)
    end

    it "calls #update on a new instance" do
      expect(instance).to have_received(:update).once
    end
  end

  describe "#update" do
    let(:copyright_statement_before) { "My First Copyright Statement" }
    let(:instance) do
      described_class.new(model, change_set)
    end
    let(:license_before) { "https://opendatacommons.org/licenses/pddl/1-0/" }
    let(:model) do
      model = Cocina::Models::DRO.new(
        externalIdentifier: "druid:bc123df4568",
        label: "test",
        type: Cocina::Models::ObjectType.object,
        version: 1,
        description: {
          title: [{value: "test"}],
          purl: "https://purl.stanford.edu/bc123df4568"
        },
        access: {
          copyright: copyright_statement_before,
          license: license_before,
          useAndReproductionStatement: use_statement_before
        },
        identification: {
          barcode: barcode_before,
          catalogLinks: [{catalog: CatalogRecordId.type, catalogRecordId: catalog_record_id_before, refresh: true}],
          sourceId: "sul:1234"
        },
        structural: {},
        administrative: {hasAdminPolicy: "druid:bc123df4569"}
      )
      Cocina::Models.with_metadata(model, "abc123")
    end
    let(:use_statement_before) { "My First Use Statement" }
    let(:barcode_before) { "36105014757517" }
    let(:catalog_record_id_before) { "a367268" }
    let(:change_set) { ItemChangeSet.new(model) }

    before do
      allow(Repository).to receive(:store)
    end

    context "when change set has changed copyright statement" do
      let(:new_copyright_statement) { "A Changed Copyright Statement" }

      before do
        change_set.validate(copyright: new_copyright_statement)
        instance.update
      end

      it "invokes object client with item/DRO that has new copyright statement" do
        expect(Repository).to have_received(:store).with(
          cocina_object_with(
            access: {
              copyright: new_copyright_statement,
              license: license_before,
              useAndReproductionStatement: use_statement_before
            }
          )
        )
      end
    end

    context "when change set has changed license" do
      let(:new_license) { "https://creativecommons.org/licenses/by-nc-nd/3.0/legalcode" }

      before do
        change_set.validate(license: new_license)
        instance.update
      end

      it "invokes object client with item/DRO that has new license" do
        expect(Repository).to have_received(:store).with(
          cocina_object_with(
            access: {
              copyright: copyright_statement_before,
              license: new_license,
              useAndReproductionStatement: use_statement_before
            }
          )
        )
      end
    end

    context "when change set has changed use statement" do
      let(:new_use_statement) { "A Changed Use Statement" }

      before do
        change_set.validate(use_statement: new_use_statement)
        instance.update
      end

      it "invokes object client with item/DRO that has new use statement" do
        expect(Repository).to have_received(:store).with(
          cocina_object_with(
            access: {
              copyright: copyright_statement_before,
              license: license_before,
              useAndReproductionStatement: new_use_statement
            }
          )
        )
      end
    end

    context "when change set has one changed property and another nil" do
      let(:model) do
        model = Cocina::Models::DRO.new(
          externalIdentifier: "druid:bc123df4568",
          label: "test",
          type: Cocina::Models::ObjectType.object,
          version: 1,
          description: {
            title: [{value: "test"}],
            purl: "https://purl.stanford.edu/bc123df4568"
          },
          access: {
            # NOTE: missing copyright here
            license: license_before,
            useAndReproductionStatement: use_statement_before
          },
          identification: {sourceId: "sul:1234"},
          structural: {},
          administrative: {hasAdminPolicy: "druid:bc123df4569"}
        )
        Cocina::Models.with_metadata(model, "abc123")
      end
      let(:new_use_statement) { "A Changed Use Statement" }

      before do
        change_set.validate(use_statement: new_use_statement)
        instance.update
      end

      it "invokes object client with item/DRO that has new use statement" do
        expect(Repository).to have_received(:store).with(
          cocina_object_with(
            access: {
              license: license_before,
              useAndReproductionStatement: new_use_statement
            }
          )
        )
      end
    end

    context "when change set has no changes" do
      before do
        instance.update
      end

      it "invokes object client with item/DRO as before" do
        expect(Repository).to have_received(:store).with(
          cocina_object_with(
            access: {
              copyright: copyright_statement_before,
              license: license_before,
              useAndReproductionStatement: use_statement_before
            }
          )
        )
      end
    end

    context "when change set has changed barcode" do
      let(:new_barcode) { "36105014757518" }

      before do
        change_set.validate(barcode: new_barcode)
        instance.update
      end

      it "invokes object client with item/DRO that has new barcode" do
        expect(Repository).to have_received(:store).with(
          cocina_object_with(
            identification: {
              barcode: new_barcode,
              catalogLinks: [{catalog: CatalogRecordId.type, catalogRecordId: catalog_record_id_before, refresh: true}]
            }
          )
        )
      end
    end

    context "when change set has removed barcode" do
      before do
        change_set.validate(barcode: nil)
        instance.update
      end

      it "invokes object client with item/DRO that has no barcode" do
        expect(Repository).to have_received(:store).with(
          cocina_object_with(
            identification: {
              barcode: nil,
              catalogLinks: [{catalog: CatalogRecordId.type, catalogRecordId: catalog_record_id_before, refresh: true}]
            }
          )
        )
      end
    end

    context "when change set has changed refresh" do
      let(:new_catalog_record_ids) { ["367269"] }

      before do
        change_set.validate(catalog_record_ids: [catalog_record_id_before], refresh: false)
        instance.update
      end

      it "invokes object client with item/DRO that has new catalog_record_id" do
        expect(Repository).to have_received(:store).with(
          cocina_object_with(
            identification: {
              barcode: barcode_before,
              catalogLinks: [
                {catalog: CatalogRecordId.type, catalogRecordId: catalog_record_id_before, refresh: false}
              ]
            }
          )
        )
      end
    end

    context "when change set has changed catalog_record_id" do
      let(:new_catalog_record_ids) { ["a367269"] }

      before do
        change_set.validate(catalog_record_ids: new_catalog_record_ids)
        instance.update
      end

      it "invokes object client with item/DRO that has new catalog_record_id" do
        expect(Repository).to have_received(:store).with(
          cocina_object_with(
            identification: {
              barcode: barcode_before,
              catalogLinks: [
                {catalog: CatalogRecordId.previous_type, catalogRecordId: catalog_record_id_before, refresh: false},
                {catalog: CatalogRecordId.type, catalogRecordId: new_catalog_record_ids.first, refresh: true}
              ]
            }
          )
        )
      end
    end

    context "when change set has removed catalog_record_id" do
      before do
        change_set.validate(catalog_record_ids: [])
        instance.update
      end

      it "invokes object client with item/DRO that has no catalog_record_id" do
        expect(Repository).to have_received(:store).with(
          cocina_object_with(
            identification: {
              catalogLinks: [{catalog: CatalogRecordId.previous_type, catalogRecordId: catalog_record_id_before, refresh: false}],
              barcode: barcode_before
            }
          )
        )
      end
    end

    context "when change set has changed APO" do
      before do
        change_set.validate(admin_policy_id: new_apo)
        instance.update
      end

      let(:new_apo) { "druid:dc123df4569" }

      it "invokes object client with collection that has new APO" do
        expect(Repository).to have_received(:store).with(
          cocina_object_with(
            administrative: {
              hasAdminPolicy: new_apo
            }
          )
        )
      end
    end
  end
end
