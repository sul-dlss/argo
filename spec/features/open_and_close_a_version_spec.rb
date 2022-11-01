# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Open and close a version" do
  let(:item) do
    FactoryBot.create_for_repository(:persisted_item)
  end

  let(:dsc) { Dor::Services::Client.object(item.externalIdentifier) }

  before do
    sign_in create(:user), groups: ["sdr:administrator-role"]
    dsc.accession.start(workflow: "accessionWF", significance: "major", description: "test version")
  end

  it "opens an object", js: true do
    visit solr_document_path item.externalIdentifier
    10.times do
      # Ensure every step of accessionWF is completed, this will allow us to open a new version.
      click_link "accessionWF"
      click_button "Set to completed", match: :first
    end

    sleep 1 # Give time for a reindex to occur.
    visit solr_document_path item.externalIdentifier
    click_link "Unlock to make changes to this object"
    select "Minor", from: "Type"
    fill_in "Version description", with: "Test a change"

    click_button "Open Version"
    expect(page).to have_content "#{item.externalIdentifier} is open for modification!"

    click_link "Close Version"
    expect(page).to have_content "Test a change"

    click_button "Close Version"

    expect(page).to have_content "Version 2 of #{item.externalIdentifier} has been closed!"
  end
end
