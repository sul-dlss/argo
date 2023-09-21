# frozen_string_literal: true

require "rails_helper"

RSpec.describe "retrieve a token for sdr-api", :js do
  let(:conn) { instance_double(SdrClient::Connection, post: response) }
  let(:response) { instance_double(Faraday::Response, status: 200, body:) }
  let(:body) do
    '{"token":"zaa","exp":"2020-04-19"}'
  end

  before do
    allow(SdrClient::Login).to receive(:run)
    allow(SdrClient::Credentials).to receive(:read)
    allow(SdrClient::Connection).to receive(:new).and_return(conn)
  end

  context "when user is not authorized" do
    let(:groups) { ["sdr:administrator-role", "dlss:dor-admin", "dlss:developers"] }

    it "forbids access to tokens" do
      sign_in create(:user), groups: groups

      visit "/settings/tokens"
      expect(page).to have_text("forbidden")
      expect(SdrClient::Login).not_to have_received(:run)
    end
  end

  context "when user is authorized" do
    let(:groups) { ["sdr:api-authorized-users"] }

    it "gets a token" do
      sign_in create(:user), groups: groups

      visit "/settings/tokens"
      click_button "Generate new token"
      expect(find_field("Token").value).to eq body
      expect(SdrClient::Login).to have_received(:run)
    end
  end
end
