# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Registration catalog_record_id check" do
  let(:user) { create(:user) }
  let(:marcxml_client) { instance_double(Dor::Services::Client::Marcxml) }

  before do
    sign_in user
    allow(Dor::Services::Client).to receive(:marcxml).and_return(marcxml_client)
  end

  context "when catalog_record_id found" do
    before do
      allow(marcxml_client).to receive(:marcxml).and_return(true)
    end

    it "returns true" do
      get "/registration/catalog_record_id?catalog_record_id=123"

      expect(response.body).to eq("true")
      expect(marcxml_client).to have_received(:marcxml).with(catkey: "123")
    end
  end

  context "when catalog_record_id not found" do
    before do
      allow(marcxml_client).to receive(:marcxml).and_raise(Dor::Services::Client::NotFoundResponse)
    end

    it "returns false" do
      get "/registration/catalog_record_id?catalog_record_id=123"

      expect(response.body).to eq("false")
    end
  end

  context "when other error" do
    before do
      allow(marcxml_client).to receive(:marcxml).and_raise(Dor::Services::Client::UnexpectedResponse.new(response: nil))
    end

    it "returns true" do
      get "/registration/catalog_record_id?catalog_record_id=123"

      expect(response.body).to eq("true")
    end
  end

  context "when other error and production" do
    before do
      allow(Rails.env).to receive(:production?).and_return(true)

      allow(marcxml_client).to receive(:marcxml).and_raise(Dor::Services::Client::UnexpectedResponse.new(response: "",
        errors: [{title: "Oops!"}]))
    end

    it "returns 500" do
      get "/registration/catalog_record_id?catalog_record_id=123"

      expect(response).to have_http_status(:bad_gateway)
    end
  end
end
