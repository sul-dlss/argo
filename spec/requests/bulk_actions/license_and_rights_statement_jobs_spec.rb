# frozen_string_literal: true

require "rails_helper"

RSpec.describe "BulkActions::LicenseAndRightsStatementJobs", type: :request do
  let(:rendered) do
    Capybara::Node::Simple.new(response.body)
  end

  describe "GET #new" do
    before do
      sign_in build(:user), groups: ["sdr:administrator-role"]
    end

    it "draws the form" do
      get "/bulk_actions/license_and_rights_statement_job/new"

      expect(rendered).to have_css 'textarea[name="druids"]'
      expect(rendered).to have_css 'textarea[name="description"]'
      expect(rendered).to have_css 'input[type="checkbox"][value="1"][name="use_statement_option"]'
      expect(rendered).to have_css 'textarea[name="use_statement"]'
      expect(rendered).to have_css 'input[type="checkbox"][value="1"][name="copyright_statement_option"]'
      expect(rendered).to have_css 'textarea[name="copyright_statement"]'
      expect(rendered).to have_css 'input[type="checkbox"][value="1"][name="license_option"]'
      expect(rendered).to have_css 'select[name="license"]'
      expect(rendered).to have_css 'option[value=""]'
      expect(rendered).to have_css 'option[value="https://creativecommons.org/licenses/by-sa/3.0/legalcode"]'
    end
  end
end
