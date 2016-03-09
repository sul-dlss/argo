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
  describe 'POST reset' do
    let(:workflow) { 'accessionWF' }
    let(:step) { 'descriptive-metadata' }
    let(:ids) { [1, 2, 3, 4, 5] }
    it 'sets instance variable and calls update workflow service' do
      expect(controller).to receive(:pids_from_report).and_return(ids)
      expect(controller).to receive(:repo_from_workflow)
        .and_return('dor')
      ids.each do |id|
        expect(Dor::Config.workflow.client).to receive(:update_workflow_status)
          .with('dor', "druid:#{id}", workflow, step, 'waiting')
      end
      xhr :post, :reset, reset_workflow: workflow, reset_step: step
      expect(assigns(:workflow)).to eq workflow
      expect(assigns(:step)).to eq step
      expect(assigns(:ids)).to eq ids
      expect(response.status).to eq 200
    end
    it 'gets the correct pids from a new Report' do
      expect(Report).to receive(:new).and_return(double('report', pids: []))
      xhr :post, :reset, reset_workflow: workflow, reset_step: step
      expect(response.status).to eq 200
    end
    it 'gets repo from the WorkflowObject' do
      expect(controller).to receive(:pids_from_report).and_return([])
      expect(Dor::WorkflowObject).to receive(:find_by_name)
        .and_return double(definition: double(repo: 'dor'))
      xhr :post, :reset, reset_workflow: workflow, reset_step: step
      expect(assigns(:repo)).to eq 'dor'
      expect(response.status).to eq 200
    end
  end
  describe 'download' do
    it 'should download valid CSV data' do
      get :download, fields: ' '
      expect(response).to have_http_status(:ok)
      expect(response.header['Content-Disposition']).to eq('attachment; filename=report.csv')
      expect { CSV.parse(response.body) }.not_to raise_error
    end
    it 'should download valid CSV data for specific fields' do
      get :download, fields: 'druid,purl,source_id_ssim,tag_ssim'
      expect(response).to have_http_status(:ok)
      expect(response.body.strip).to eq('"Druid","Purl","Source Id","Tags"')
    end
  end
  describe 'config' do
    let(:config) { controller.blacklight_config }
    it 'should use POST as the http method' do
      expect(config.http_method).to eq :post
    end
  end
end
