require 'spec_helper'

describe ReportController, :type => :controller do
  before :each do
    log_in_as_mock_user(subject)
    allow_any_instance_of(User).to receive(:groups).and_return(['sdr:administrator-role'])
  end
  describe ':workflow_grid' do
    it 'should work' do
      get :workflow_grid
      expect(response).to render_template('workflow_grid')
    end
    it 'should work in :format => json' do
      get :workflow_grid, :format => :json
      expect(response).to render_template('workflow_grid')
    end
  end
  describe ':data' do
    it 'should return json' do
      get :data, :format => :json, :rows => 5
      expect{ JSON.parse(response.body) }.not_to raise_error()
    end
    it 'should default to 10 rows per page, rather than defaulting to 0 and generating an exception when the number of pages is infinity when no row count is passed in' do
      get :data, :format => :json
      expect{ JSON.parse(response.body) }.not_to raise_error()
    end
  end
  describe 'bulk' do
    it 'should render the correct template' do
      get :bulk
      expect(response).to render_template('bulk')
    end
  end
end
