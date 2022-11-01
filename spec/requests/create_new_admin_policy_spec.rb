# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Create a new Admin Policy" do
  let(:user) { create(:user) }

  before do
    sign_in user, groups: ["sdr:administrator-role"]
  end

  context "when the parameters are invalid" do
    it "redraws the form" do
      post "/apo", params: {apo: {title: ""}}
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
