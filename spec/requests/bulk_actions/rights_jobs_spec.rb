# frozen_string_literal: true

require "rails_helper"

RSpec.describe "BulkActions::RightsJobs" do
  describe "create" do
    let(:user) { build(:user) }

    before do
      sign_in user, groups: ["sdr:administrator-role"]
    end

    it "creates a job" do
      params = {"view_access" => "world", "download_access" => "stanford",
                "controlled_digital_lending" => "0",
                "f" => {"objectType_ssim" => ["agreement"]},
                "q" => "", "search_field" => "text", "druids" => "druid:cf540ct6282", "description" => ""}

      expect { post "/bulk_actions/rights_job", params: }.to have_enqueued_job(SetRightsJob)
        .with(Integer, {
          druids: ["druid:cf540ct6282"],
          groups: ["sunetid:#{user.login}", "workgroup:sdr:administrator-role"],
          view_access: "world",
          download_access: "stanford",
          controlled_digital_lending: "0"
        })
      expect(response).to have_http_status(:see_other)
    end
  end
end
