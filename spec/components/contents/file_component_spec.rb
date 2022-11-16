# frozen_string_literal: true

require "rails_helper"

RSpec.describe Contents::FileComponent, type: :component do
  let(:component) { described_class.new(file:, object_id: "druid:kb487gt5106", viewable: true, image: true) }
  let(:rendered) { render_inline(component) }
  let(:file) do
    instance_double(Cocina::Models::File,
      filename: "example.tif",
      externalIdentifier: "https://cocina.sul.stanford.edu/file/b7cdfa7a-6e1f-484b-bbb0-f9a46c40dbb4",
      hasMimeType: "image/tiff",
      size: 99,
      access:,
      administrative: admin,
      presentation:,
      use:)
  end

  let(:access) { instance_double(Cocina::Models::FileAccess, view: "world", download: "stanford") }
  let(:admin) { instance_double(Cocina::Models::FileAdministrative, sdrPreserve: true, publish: true, shelve: true) }
  let(:presentation) { instance_double(Cocina::Models::Presentation, height: 11_839, width: 19_380) }
  let(:use) { "transcription" }

  context "with an image fileset" do
    it "renders the component" do
      expect(rendered.css('a[href="/items/druid:kb487gt5106/files?id=example.tif"]').to_html)
        .to include("example.tif")
      expect(rendered.to_html).to include "World"
      expect(rendered.to_html).to include "Stanford"
      expect(rendered.to_html).to include "Transcription"
      expect(rendered.to_html).to include "11839 px"
    end
  end

  context "with no file use set" do
    let(:use) { nil }

    it "renders the component" do
      expect(rendered.to_html).to include "No role"
    end
  end

  context "with no presentation" do
    let(:presentation) { nil }

    it "renders the component" do
      expect(rendered.to_html).to include "World"
    end
  end

  context "with a fileset that is not an image" do
    let(:component) { described_class.new(file:, object_id: "druid:kb487gt5106", viewable: true, image: false) }

    it "renders the component without height" do
      expect(rendered.to_html).to include "World"
      expect(rendered.to_html).not_to include "11839 px"
    end
  end

  context "with location-based view" do
    let(:access) { instance_double(Cocina::Models::FileAccess, view: "location-based", location: "hoover", download: "none") }

    it "renders the view location" do
      expect(rendered.to_html).to include "hoover"
      expect(rendered.to_html).to include "None"
    end
  end

  context "with location-based download" do
    let(:access) { instance_double(Cocina::Models::FileAccess, view: "stanford", location: "hoover", download: "location-based") }

    it "renders the donwload location" do
      expect(rendered.to_html).to include "Stanford"
      expect(rendered.to_html).to include "hoover"
    end
  end
end
