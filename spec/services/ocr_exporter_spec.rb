# frozen_string_literal: true

require "rails_helper"

RSpec.describe OCRExporter do
  subject(:exporter) { described_class.new(filename, "tmp/", finder:) }

  let(:filename) { "barcodes.txt" }
  let(:finder) { instance_double(described_class::DruidFinder, find_druid: []) }
  let(:client1) { instance_double(Dor::Services::Client::Object, find: cocina1) }
  let(:client2) { instance_double(Dor::Services::Client::Object, find: cocina2) }
  let(:cocina1) { instance_double(Cocina::Models::DRO, version: 1, structural: struct1) }
  let(:cocina2) { instance_double(Cocina::Models::DRO, version: 1, structural: struct2) }
  let(:struct1) { Cocina::Models::DROStructural.new(contains: [fs1, fs2]) }
  let(:struct2) { Cocina::Models::DROStructural.new(contains: [fs3, fs4]) }
  let(:fs1) do
    {
      externalIdentifier: "fs1",
      label: "fs1",
      type: Cocina::Models::FileSetType.file,
      version: 1,
      structural: {
        contains: [
          {
            externalIdentifier: "fs1/fs1-gb-jp2.zip",
            type: Cocina::Models::ObjectType.file,
            version: 1,
            hasMimeType: "application/zip",
            label: "fs1-gb-jp2.zip",
            filename: "fs1-gb-jp2.zip"
          }
        ]
      }
    }
  end
  let(:fs2) do
    {
      externalIdentifier: "fs2", label: "fs2", type: Cocina::Models::FileSetType.file,
      version: 1,
      structural: {
        contains: [
          {
            externalIdentifier: "fs2/fs2-gb-txt.zip",
            type: Cocina::Models::ObjectType.file,
            version: 1,
            hasMimeType: "application/zip",
            label: "fs2-gb-txt.zip",
            filename: "fs2-gb-txt.zip"
          }
        ]
      }
    }
  end
  let(:fs3) do
    {
      externalIdentifier: "fs3",
      label: "fs3",
      type: Cocina::Models::FileSetType.file,
      version: 1,
      structural: {
        contains: [
          {
            externalIdentifier: "fs3/fs3-gb-jp2.zip",
            type: Cocina::Models::ObjectType.file,
            version: 1,
            hasMimeType: "application/zip",
            label: "fs3-gb-jp2.zip",
            filename: "fs3-gb-jp2.zip"
          }
        ]
      }
    }
  end
  let(:fs4) do
    {
      externalIdentifier: "fs4",
      label: "fs4",
      type: Cocina::Models::FileSetType.file,
      version: 1,
      structural: {
        contains: [
          {
            externalIdentifier: "fs4/fs4-gb-txt.zip",
            type: Cocina::Models::ObjectType.file,
            version: 1,
            hasMimeType: "application/zip",
            label: "fs4-gb-txt.zip",
            filename: "fs4-gb-txt.zip"
          }
        ]
      }
    }
  end

  before do
    allow(finder).to receive(:find_druid).and_return("druid:one", "druid:two")
    allow(Dor::Services::Client).to receive(:object).and_return(client1, client2)
    allow(File).to receive(:open).and_call_original
    allow(File).to receive(:open).with(filename, "r").and_return(%W[00001231\n 00002222\n])

    FileUtils.rm_r("tmp/druid:one") if File.directory? "tmp/druid:one"
    FileUtils.rm_r("tmp/druid:two") if File.directory? "tmp/druid:two"

    allow(Preservation::Client.objects).to receive(:content).and_return("content1", "content2")
  end

  it "downloads files" do
    exporter.export

    expect(File).to exist("tmp/druid:one/fs2-gb-txt.zip")
    expect(File).to exist("tmp/druid:two/fs4-gb-txt.zip")
  end
end
