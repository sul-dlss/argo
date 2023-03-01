# frozen_string_literal: true

require "rails_helper"

RSpec.describe TrackSheet do
  let(:druid) { "xb482ww9999" }
  let(:instance) { described_class.new([druid]) }

  describe "#find_or_create_in_solr_by_id" do
    subject(:call) { instance.send(:find_or_create_in_solr_by_id, druid) }

    before do
      allow(SearchService).to receive(:query)
        .with("id:\"druid:#{druid}\"", rows: 1)
        .and_return(response)
    end

    let(:response) { {"response" => {"docs" => docs}} }
    let(:solr_doc) { instance_double(Hash) }

    context "when the doc is found in solr" do
      let(:docs) { [solr_doc] }

      it "returns the document" do
        expect(call).to eq solr_doc
      end
    end

    context "when the doc is not in the search results" do
      before do
        allow(Argo::Indexer).to receive(:reindex_druid_remotely)

        allow(SearchService).to receive(:query)
          .with("id:\"druid:#{druid}\"", rows: 1)
          .and_return(response, second_response)
      end

      let(:docs) { [] }
      let(:second_response) { {"response" => {"docs" => [solr_doc]}} }

      it "reindexes and and tries again" do
        expect(call).to eq solr_doc
      end
    end
  end

  # NOTE: the test expectations here use "include" instead of "eq" because the tracking sheet adds a timestamp to the array, which can be flaky to test against
  describe "#doc_to_table" do
    subject(:call) { instance.send(:doc_to_table, solr_doc) }

    let(:base_solr_doc) do
      {
        "obj_label_tesim" => ["bogus label"] # the fedora label
      }
    end

    context "normal length title" do
      let(:solr_doc) do
        base_solr_doc.merge(
          {
            "sw_display_title_tesim" => ["Correct title"] # the cocina title
          }
        )
      end

      it "builds the table for the solr doc with the correct title" do
        expect(call).to include(
          [
            "Object Label:",
            "Correct title" # we get the cocina title out!
          ]
        )
      end
    end

    context "really long title" do
      let(:solr_doc) do
        base_solr_doc.merge(
          {
            "sw_display_title_tesim" => ["Stanford University. School of Engineeering Roger Howe Professorship: Stanford (Calif.), 2010-01-21.  And more stuff goes here"]
          }
        )
      end

      it "builds the table for the solr doc with a truncated title" do
        expect(call).to include(
          [
            "Object Label:",
            "Stanford University. School of Engineeering Roger Howe Professorship: Stanford (Calif.), 2010-01-21.  And m..."
          ]
        )
      end
    end

    context "no title" do
      let(:solr_doc) do
        base_solr_doc.merge({
          "sw_display_title_tesim" => [""]

        })
      end

      it "builds the table for the solr doc with a blank title" do
        expect(call).to include(
          [
            "Object Label:",
            ""
          ]
        )
      end
    end

    context "with a project name" do
      let(:solr_doc) do
        base_solr_doc.merge(
          {
            "project_tag_ssim" => ["School of Engineering photograph collection"]
          }
        )
      end

      it "adds the project name" do
        expect(call).to include(
          [
            "Project Name:",
            '["School of Engineering photograph collection"]'
          ]
        )
      end
    end

    context "with tags" do
      let(:solr_doc) do
        base_solr_doc.merge(
          {
            "tag_ssim" => [
              "Some : First : Tag",
              "Some : Second : Tag",
              "Project : Ignored"
            ]
          }
        )
      end

      it "adds the tags, ignoring a project tag" do
        expect(call).to include(
          [
            "Tags:",
            "Some : First : Tag\nSome : Second : Tag"
          ]
        )
      end
    end

    context "with a catalog_record_id" do
      let(:solr_doc) do
        base_solr_doc.merge({
          CatalogRecordId.index_field => ["catkey123"]
        })
      end

      it "adds the catkey" do
        expect(call).to include(
          [
            "Catkey:",
            "catkey123"
          ]
        )
      end
    end

    context "with a source_id" do
      let(:solr_doc) do
        base_solr_doc.merge({
          "source_id_ssim" => ["source:123"]
        })
      end

      it "adds the catalog_record_id" do
        expect(call).to include(
          [
            "Source ID:",
            "source:123"
          ]
        )
      end
    end

    context "with a barcode" do
      let(:solr_doc) do
        base_solr_doc.merge({
          "barcode_id_ssim" => ["barcode123"]
        })
      end

      it "adds the catalog_record_id" do
        expect(call).to include(
          [
            "Barcode:",
            "barcode123"
          ]
        )
      end
    end
  end
end
