# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkflowsController, type: :controller do
  let(:pid) { 'druid:oo201oo0001' }
  let(:item) { Dor::Item.new pid: pid }
  let(:user) { create(:user) }

  before do
    sign_in user
    allow(Dor).to receive(:find).with(pid).and_return(item)
  end

  describe '#create' do
    context 'when they have manage_content access' do
      let(:wf_datastream) { instance_double(Dor::WorkflowDs) }

      before do
        allow(item).to receive(:to_solr)
        allow(Dor::SearchService.solr).to receive(:add)
        allow(controller).to receive(:authorize!).and_return(true)
        allow(item).to receive(:workflows).and_return wf_datastream
      end

      it 'initializes the new workflow' do
        expect(Dor::CreateWorkflowService).to receive(:create_workflow).with(item, name: 'accessionWF')
        expect(wf_datastream).to receive(:[]).with('accessionWF').and_return(nil)
        expect(controller).to receive(:flush_index)
        post :create, params: { item_id: pid, wf: 'accessionWF' }
      end

      it 'does not initialize the workflow if one is already active' do
        expect(item).not_to receive(:create_workflow)
        mock_wf = double
        expect(mock_wf).to receive(:active?).and_return(true)
        expect(wf_datastream).to receive(:[]).and_return(mock_wf)
        post :create, params: { item_id: pid, wf: 'accessionWF' }
      end
    end
  end

  describe '#show' do
    let(:workflow) { instance_double(Dor::Workflow::Document) }

    it 'requires workflow and repo parameters' do
      expect { get :show, params: { item_id: pid, id: 'accessionWF' } }.to raise_error(ActionController::ParameterMissing)
    end

    it 'fetches the workflow on valid parameters' do
      expect(item.workflows).to receive(:get_workflow).and_return(workflow)
      get :show, params: { item_id: pid, id: 'accessionWF', repo: 'dor', format: :html }
      expect(response).to have_http_status(:ok)
      expect(assigns[:workflow]).to eq workflow
    end

    it 'returns 404 on missing item' do
      expect(Dor).to receive(:find).with(pid).and_raise(ActiveFedora::ObjectNotFoundError)
      get :show, params: { item_id: pid, id: 'accessionWF', repo: 'dor', format: :html }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe '#update' do
    it 'requires various workflow parameters' do
      expect { post :update, params: { item_id: pid, id: 'accessionWF' } }.to raise_error(ActionController::ParameterMissing)
    end

    it 'changes the status' do
      expect(Dor::WorkflowObject).to receive(:find_by_name).with('accessionWF').and_return(double(definition: double(repo: 'dor')))
      expect(Dor::Config.workflow.client).to receive(:get_workflow_status).with('dor', pid, 'accessionWF', 'publish').and_return(nil)
      expect(Dor::Config.workflow.client).to receive(:update_workflow_status).with('dor', pid, 'accessionWF', 'publish', 'ready').and_return(nil)
      post :update, params: { item_id: pid, id: 'accessionWF', process: 'publish', status: 'ready' }
      expect(subject).to redirect_to(solr_document_path(pid))
    end
  end
end
