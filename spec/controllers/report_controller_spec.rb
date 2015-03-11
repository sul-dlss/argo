require 'spec_helper'

describe ReportController, :type => :controller do
  describe ":workflow_grid" do
    it "should work" do
      log_in_as_mock_user(subject)
      allow_any_instance_of(User).to receive(:groups).and_return(['sdr:administrator-role'])
      get :workflow_grid
      expect(response).to render_template('workflow_grid')
    end
    it "should work in :format => json" do
      log_in_as_mock_user(subject)
      allow_any_instance_of(User).to receive(:groups).and_return(['sdr:administrator-role'])
      get :workflow_grid, :format => :json
      expect(response).to render_template('workflow_grid')
    end
  end
  describe ":data" do
    it "should return json" do
      log_in_as_mock_user(subject)
      allow_any_instance_of(User).to receive(:groups).and_return(['sdr:administrator-role'])
      get :data, :format => :json, :rows =>5
      #this throws an exception if parsing fails
      json_body=JSON.parse(response.body)
    end
    it "should default to 10 rows per page, rather than defaulting to 0 and generating an exception when the number of pages is infinity when no row count is passed in" do
      log_in_as_mock_user(subject)
      allow_any_instance_of(User).to receive(:groups).and_return(['sdr:administrator-role'])
      get :data, :format => :json
      #this throws an exception if parsing fails
      json_body=JSON.parse(response.body)
    end
  end
  
end
