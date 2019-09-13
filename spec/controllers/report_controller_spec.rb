# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReportController, type: :controller do
  before do
    # have to stub any instance, as the user is not the same instance as created here
    # TODO: we should be stubbing the SearchBuilder instead
    allow_any_instance_of(User).to receive(:is_admin?).and_return(true)
    sign_in user
  end

  let(:user) { create(:user) }

  describe '#workflow_grid' do
    it 'works' do
      get :workflow_grid
      expect(response).to have_http_status(:ok)
      expect(response).to render_template('workflow_grid')
    end
  end

  describe '#data' do
    it 'returns json' do
      get :data, params: { format: :json, rows: 5 }
      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body)
      expect(data['rows'].length).to eq(5)
    end
    it 'defaults to 10 rows per page, rather than defaulting to 0 and generating an exception when the number of pages is infinity when no row count is passed in' do
      get :data, params: { format: :json }
      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body)
      expect(data['rows'].length).to eq(10)
    end
  end

  describe '#pids' do
    it 'returns json' do
      get :pids, params: { format: :json }
      expect(response).to have_http_status(:ok)
      pids = JSON.parse(response.body)['druids']
      expect(pids).to be_a(Array)
      expect(pids.length > 1).to be_truthy
      expect(pids.first).to eq('br481xz7820')
    end
  end

  describe '#bulk' do
    it 'renders the correct template' do
      get :bulk
      expect(response).to have_http_status(:ok)
      expect(response).to render_template('bulk')
    end
  end

  describe 'POST reset' do
    let(:repo) { 'dor' }
    let(:workflow) { 'accessionWF' }
    let(:step) { 'descriptive-metadata' }

    it 'requires parameters' do
      expect { post :reset, xhr: true }.to raise_error(ActionController::ParameterMissing)
      expect { post :reset, xhr: true, params: { reset_workflow: workflow } }.to raise_error(ActionController::ParameterMissing)
      expect { post :reset, xhr: true, params: { reset_step: step } }.to raise_error(ActionController::ParameterMissing)
    end
    it 'sets instance variables and calls update workflow service' do
      expect(controller).to receive(:repo_from_workflow)
        .and_return(repo)
      expect(Dor::Config.workflow.client).to receive(:update_workflow_status)
        .with(repo, 'druid:xb482bw3979', workflow, step, 'waiting')
      post :reset, xhr: true, params: { reset_workflow: workflow, reset_step: step, q: 'Cephalopods' } # has single match
      expect(assigns(:workflow)).to eq workflow
      expect(assigns(:step)).to eq step
      expect(assigns(:ids)).to eq(%w(xb482bw3979))
      expect(assigns(:repo)).to eq(repo)
      expect(response).to have_http_status(:ok)
    end
    it 'gets repo from the WorkflowObject' do
      expect(Dor::WorkflowObject).to receive(:find_by_name)
        .and_return double(definition: double(repo: repo)) # mocks dor-services call
      post :reset, xhr: true, params: { reset_workflow: workflow, reset_step: step, q: 'NoMatchesForThisString' }
      expect(assigns(:repo)).to eq repo
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'download' do
    it 'downloads valid CSV data' do
      get :download, params: { fields: ' ' }
      expect(response).to have_http_status(:ok)
      expect(response.header['Content-Disposition']).to eq('attachment; filename=report.csv')
      data = CSV.parse(response.body)
      expect(data.first.length).to eq(25)
      expect(data.length > 1).to be_truthy
      expect(data[1].first).to eq('br481xz7820') # first data row starts with pid
    end
    it 'downloads valid CSV data for specific fields' do
      get :download, params: { fields: 'druid,purl,source_id_ssim,tag_ssim' }
      expect(response).to have_http_status(:ok)
      data = CSV.parse(response.body)
      expect(data.first).to eq(%w(Druid Purl Source\ Id Tags))
      expect(data.length > 1).to be_truthy
      expect(data[1].first).to eq('br481xz7820') # first data row starts with pid
    end
  end

  describe '#config' do
    let(:config) { controller.blacklight_config }

    it 'uses POST as the http method' do
      expect(config.http_method).to eq :post
    end
  end
end
