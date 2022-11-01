# frozen_string_literal: true

require "rails_helper"

RSpec.describe "BulkActions::ImportStructuralJobs", type: :request do
  describe "create" do
    let(:user) { build(:user) }

    before do
      sign_in user, groups: ["sdr:administrator-role"]
    end

    it "creates a job" do
      params = {"csv_file" => fixture_file_upload("bulk_upload_structural.csv", "text/csv")}

      expect { post "/bulk_actions/import_structural_job", params: }.to have_enqueued_job(ImportStructuralJob)
        .with(Integer, {
          groups: ["sunetid:#{user.login}", "workgroup:sdr:administrator-role"],
          csv_file: String
        })
      expect(response).to have_http_status(:see_other)
    end

    context "when invalid csv" do
      it "does not create the job" do
        params = {"csv_file" => fixture_file_upload("invalid_bulk_upload_structural.csv", "text/csv")}

        expect { post "/bulk_actions/import_structural_job", params: }.not_to have_enqueued_job(ImportStructuralJob)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to match("missing headers: druid")
      end
    end
  end
end
