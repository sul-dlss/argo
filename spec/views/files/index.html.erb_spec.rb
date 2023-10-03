# frozen_string_literal: true

require "rails_helper"

RSpec.describe "files/index" do
  let(:admin) { instance_double(Cocina::Models::FileAdministrative, shelve: true, sdrPreserve: true) }
  let(:file_url) { "https://stacks-test.stanford.edu/file/druid:rn653dy9317/M1090_S15_B01_F07_0106.jp2" }

  before do
    @file = instance_double(Cocina::Models::File, administrative: admin, access: access)
    @has_been_accessioned = true
    @last_accessioned_version = "7"
    params[:id] = "M1090_S15_B01_F07_0106.jp2"
    params[:item_id] = "druid:rn653dy9317"
    render
  end

  context "when download access is world" do
    let(:access) { instance_double(Cocina::Models::FileAccess, download: "world") }

    it "renders the partial content with links" do
      expect(rendered).to have_content "Stacks"
      expect(rendered).to have_content "Preservation"
      expect(rendered).to have_link file_url, href: file_url
      expect(rendered).not_to have_content "(not available for download)"
    end
  end

  context "when download access is none" do
    let(:access) { instance_double(Cocina::Models::FileAccess, download: "none") }

    it "renders the partial content without links" do
      expect(rendered).to have_content "Stacks"
      expect(rendered).to have_content "Preservation"
      expect(rendered).not_to have_link file_url, href: file_url
      expect(rendered).to have_content "(not available for download)"
    end
  end
end
