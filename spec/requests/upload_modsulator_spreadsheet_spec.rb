# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Upload a spreadsheet for modsulator" do
  let(:user) { create(:user) }
  let(:apo_id) { "abc123" }

  before do
    sign_in user
  end

  describe "draw the upload form" do
    it "is successful" do
      get "/apos/#{apo_id}/uploads/new"
      expect(response).to be_successful
    end
  end

  describe "save the upload" do
    let(:file) { fixture_file_upload("crowdsourcing_bridget_1.xlsx") }

    before do
      allow(ModsulatorJob).to receive(:perform_later)
    end

    it "is successful" do
      post "/apos/#{apo_id}/uploads", params: {
        spreadsheet_file: file,
        filetypes: "spreadsheet",
        note: "test note"
      }
      expect(ModsulatorJob).to have_received(:perform_later)
        .with("abc123", String, String, user, user.groups, "spreadsheet", "test note")
      expect(response).to redirect_to apo_bulk_jobs_path(apo_id)
      expect(flash[:notice]).to eq "Bulk processing started"
    end
  end
end
