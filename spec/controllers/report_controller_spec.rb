# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReportController, type: :controller do
  before do
    sign_in user
  end

  let(:user) { create(:user) }

  context 'as an admin' do
    before do
      allow(controller.current_user).to receive(:is_admin?).and_return(true)
    end

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
      it 'returns data for custom date searches (i.e. with user custom entered dates)' do
        params = { f: { modified_latest_dttsi: ['[2015-10-01T00:00:00.000Z TO 2050-10-07T23:59:59.000Z]'] }, format: :json, rows: 5 }
        get :data, params: params
        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)
        expect(data['rows'].length).to eq(5)
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

    describe 'download' do
      it 'downloads valid CSV data' do
        get :download, params: { fields: ' ' }
        expect(response).to have_http_status(:ok)
        expect(response.header['Content-Disposition']).to eq('attachment; filename=report.csv')
        data = CSV.parse(response.body)
        expect(data.first.length).to eq(26)
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
  end

  describe 'POST reset' do
    let(:workflow) { 'accessionWF' }
    let(:step) { 'descriptive-metadata' }
    let(:obj) { instance_double Dor::Item }
    let(:workflow_client) { instance_double(Dor::Workflow::Client, update_status: true) }

    before do
      allow(Dor::Workflow::Client).to receive(:new).and_return(workflow_client)
    end

    it 'requires parameters' do
      expect { post :reset, xhr: true }.to raise_error(ActionController::ParameterMissing)
      expect { post :reset, xhr: true, params: { reset_workflow: workflow } }.to raise_error(ActionController::ParameterMissing)
      expect { post :reset, xhr: true, params: { reset_step: step } }.to raise_error(ActionController::ParameterMissing)
    end

    context 'as an admin' do
      before do
        allow(controller.current_user).to receive(:is_admin?).and_return(true)
      end

      it 'sets instance variables and calls update workflow service' do
        post :reset, xhr: true, params: { reset_workflow: workflow, reset_step: step, q: 'Cephalopods' } # has single match
        expect(assigns(:workflow)).to eq workflow
        expect(assigns(:step)).to eq step
        expect(assigns(:ids)).to eq(%w(xb482bw3979))
        expect(response).to have_http_status(:ok)
        expect(workflow_client).to have_received(:update_status)
          .with(druid: 'druid:xb482bw3979', workflow: workflow, process: step, status: 'waiting')
      end
    end

    context 'a non admin who has access' do
      before do
        # We're just forcing the search builder to return some rows (even though this user wouldn't have access)
        allow_any_instance_of(ReportSearchBuilder).to receive(:apply_gated_discovery)
        allow(controller.current_ability).to receive(:can_update_workflow?).and_return(true)
        allow(Dor).to receive(:find).with('druid:xb482bw3979').and_return(obj)
      end

      it 'sets instance variables and calls update workflow service' do
        post :reset, xhr: true, params: { reset_workflow: workflow, reset_step: step, q: 'Cephalopods' } # has single match
        expect(assigns(:workflow)).to eq workflow
        expect(assigns(:step)).to eq step
        expect(assigns(:ids)).to eq(%w(xb482bw3979))
        expect(response).to have_http_status(:ok)
        expect(controller.current_ability).to have_received(:can_update_workflow?).with('waiting', obj)
        expect(workflow_client).to have_received(:update_status)
          .with(druid: 'druid:xb482bw3979', workflow: workflow, process: step, status: 'waiting')
      end
    end

    context 'a non admin who has no access' do
      before do
        # We're just forcing the search builder to return some rows (even though this user wouldn't have access)
        allow_any_instance_of(ReportSearchBuilder).to receive(:apply_gated_discovery)
        allow(controller.current_ability).to receive(:can_update_workflow?).and_return(false)
        allow(Dor).to receive(:find).with('druid:xb482bw3979').and_return(obj)
      end

      it 'does not call update workflow service' do
        post :reset, xhr: true, params: { reset_workflow: workflow, reset_step: step, q: 'Cephalopods' } # has single match
        expect(assigns(:workflow)).to eq workflow
        expect(assigns(:step)).to eq step
        expect(assigns(:ids)).to eq(%w(xb482bw3979))
        expect(response).to have_http_status(:ok)
        expect(controller.current_ability).to have_received(:can_update_workflow?).with('waiting', obj)
        expect(workflow_client).not_to have_received(:update_status)
      end
    end
  end

  describe '#config' do
    let(:config) { controller.blacklight_config }

    it 'uses POST as the http method' do
      expect(config.http_method).to eq :post
    end
  end
end
