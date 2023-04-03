# frozen_string_literal: true

require "rails_helper"

RSpec.describe "View the full dublin core" do
  let(:user) { create(:user) }

  let(:cocina_object) do
    build(:dro, id: druid, title: "Kurdish Democratic Party")
  end
  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_object) }
  let(:druid) { "druid:bc123df4567" }

  before do
    sign_in user
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
  end

  context "as keys and values" do
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
