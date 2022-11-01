# frozen_string_literal: true

require "rails_helper"

RSpec.describe "View the full dublin core" do
  let(:user) { create(:user) }

  context "as keys and values" do
    let(:object_client) { instance_double(Dor::Services::Client::Object, metadata:) }
    let(:metadata) { instance_double(Dor::Services::Client::Metadata, dublin_core: xml) }
    let(:xml) do
      <<~XML
        <oai_dc:dc xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/">
          <dc:title>Kurdish Democratic Party</dc:title>
        </oai_dc:dc>
      XML
    end
    let(:druid) { "druid:999" }

    before do
      sign_in user
      allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
    end

    it "draws the page" do
      get "/items/#{druid}/metadata/full_dc"
      expect(response).to be_successful
      rendered = Capybara::Node::Simple.new(response.body)
      expect(rendered)
        .to have_css ".modal-header h3.modal-title", text: "Dublin Core (derived from MODS)"
      expect(rendered).to have_css ".modal-body", text: "Kurdish Democratic Party"
    end
  end

  context "as xml" do
    let(:object_client) { instance_double(Dor::Services::Client::Object, metadata:) }
    let(:metadata) { instance_double(Dor::Services::Client::Metadata, dublin_core: xml) }
    let(:xml) do
      <<~XML
        <oai_dc:dc xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/">
          <dc:title>Kurdish Democratic Party</dc:title>
        </oai_dc:dc>
      XML
    end
    let(:druid) { "druid:999" }

    before do
      sign_in user
      allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
    end

    it "draws the page" do
      get "/items/#{druid}/metadata/full_dc_xml"
      expect(response).to be_successful
      rendered = Capybara::Node::Simple.new(response.body)
      expect(rendered)
        .to have_css ".modal-header h3.modal-title", text: "Dublin Core (derived from MODS)"
      expect(rendered).to have_css ".modal-body", text: "<dc:title>Kurdish Democratic Party</dc:title>"
    end
  end
end
