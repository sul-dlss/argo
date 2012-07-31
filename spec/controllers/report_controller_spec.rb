require 'spec_helper'

describe ReportController do
  describe ":workflow_grid" do
    it "should work" do
      log_in_as_mock_user(subject)
      get :workflow_grid
      response.should render_template('workflow_grid')
    end
    it "should work in :format => json" do
      log_in_as_mock_user(subject)
      get :workflow_grid, :format => :json
      response.should render_template('workflow_grid')
    end
  end
end
