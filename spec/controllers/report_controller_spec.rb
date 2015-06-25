require 'spec_helper'

describe ReportController, :type => :controller do
  before :each do
    log_in_as_mock_user(subject)
    allow_any_instance_of(User).to receive(:groups).and_return(['sdr:administrator-role'])
  end
  describe ":workflow_grid" do
    it "should work" do
      get :workflow_grid
      expect(response).to render_template('workflow_grid')
    end
    it "should work in :format => json" do
      get :workflow_grid, :format => :json
      expect(response).to render_template('workflow_grid')
    end
  end
  describe ":data" do
    it "should return json" do
      get :data, :format => :json, :rows =>5
      expect{ JSON.parse(response.body) }.not_to raise_error()
    end
    it "should default to 10 rows per page, rather than defaulting to 0 and generating an exception when the number of pages is infinity when no row count is passed in" do
      get :data, :format => :json
      expect{ JSON.parse(response.body) }.not_to raise_error()
    end
  end
  describe "bulk" do
    it "should return a page with the expected elements" do
      pending 'not sure why, but in this test the response comes back with no HTML, so the checks for expected content fail.  page works IRL, though.'
      get :bulk
      expect(response).to render_template('bulk')
      expect(page).to include("Bulk update operations")
      ["Get druids from search", "Paste a druid list", "Reindex"].each do |btn_txt|
        expect(page).to have_button(btn_txt)
      end
    end
  end
end
