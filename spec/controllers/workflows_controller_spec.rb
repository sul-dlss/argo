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
        allow(Dor::Config.workflow.client).to receive(:get_workflow_xml).and_return(xml)

        allow(Dor::CreateWorkflowService).to receive(:create_workflow)
      end

      context 'when the workflow is not active' do
        let(:xml) { nil }

        it 'initializes the new workflow' do
          expect(controller).to receive(:flush_index)
          post :create, params: { item_id: pid, wf: 'accessionWF' }
          expect(Dor::CreateWorkflowService).to have_received(:create_workflow).with(item, name: 'accessionWF')
        end
      end

      context 'when the workflow is already active' do
        let(:xml) do
          <<~XML
            <workflow><process version="1"></workflow>
          XML
        end

        it 'does not initialize the workflow' do
          post :create, params: { item_id: pid, wf: 'accessionWF' }
          expect(Dor::CreateWorkflowService).not_to have_received(:create_workflow)
        end
      end
    end
  end

  describe '#show' do
    let(:workflow) { instance_double(Dor::Workflow::Document) }
    let(:presenter) { instance_double(WorkflowPresenter) }
    let(:workflow_status) { instance_double(WorkflowStatus) }
    let(:workflow_object) { instance_double(Dor::WorkflowObject) }

    it 'requires workflow and repo parameters' do
      expect { get :show, params: { item_id: pid, id: 'accessionWF' } }.to raise_error(ActionController::ParameterMissing)
    end

    it 'fetches the workflow on valid parameters' do
      allow(Dor::Config.workflow.client).to receive(:get_workflow_xml).and_return('xml')
      allow(WorkflowPresenter).to receive(:new).and_return(presenter)
      allow(WorkflowStatus).to receive(:new).and_return(workflow_status)
      allow(Dor::WorkflowObject).to receive(:find_by_name).with('accessionWF').and_return(workflow_object)

      get :show, params: { item_id: pid, id: 'accessionWF', repo: 'dor', format: :html }
      expect(response).to have_http_status(:ok)
      expect(WorkflowStatus).to have_received(:new)
        .with(pid: pid, workflow_name: 'accessionWF', workflow_definition: workflow_object, workflow: Dor::Workflow::Response::Workflow)
      expect(WorkflowPresenter).to have_received(:new).with(view: Object, workflow_status: workflow_status)
      expect(assigns[:presenter]).to eq presenter
    end

    it 'returns 404 on missing item' do
      expect(Dor).to receive(:find).with(pid).and_raise(ActiveFedora::ObjectNotFoundError)
      get :show, params: { item_id: pid, id: 'accessionWF', repo: 'dor', format: :html }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe '#history' do
    let(:xml) { instance_double(String) }

    it 'fetches the workflow history' do
      allow(Dor::Config.workflow.client).to receive(:get_workflow_xml).and_return(xml)
      get :history, params: { item_id: pid, format: :html }
      expect(response).to have_http_status(:ok)
      expect(assigns[:history_xml]).to eq xml
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
