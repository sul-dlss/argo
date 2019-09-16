# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkflowsController, type: :controller do
  let(:pid) { 'druid:oo201oo0001' }
  let(:item) { Dor::Item.new pid: pid }
  let(:user) { create(:user) }
  let(:workflow_client) { instance_double(Dor::Workflow::Client) }

  before do
    sign_in user
    allow(Dor).to receive(:find).with(pid).and_return(item)
    allow(Dor::Config.workflow).to receive(:client).and_return(workflow_client)
  end

  describe '#create' do
    context 'when they have manage access' do
      let(:wf_datastream) { instance_double(Dor::WorkflowDs) }
      let(:workflow_client) do
        instance_double(Dor::Workflow::Client,
                        create_workflow_by_name: true,
                        workflow: wf_response)
      end

      before do
        allow(item).to receive(:to_solr)
        allow(ActiveFedora.solr.conn).to receive(:add)
        allow(controller).to receive(:authorize!).and_return(true)
        allow(item).to receive(:workflows).and_return wf_datastream
      end

      context 'when the workflow is not active' do
        let(:wf_response) { instance_double(Dor::Workflow::Response::Workflow, active_for?: false) }

        it 'initializes the new workflow' do
          expect(controller).to receive(:flush_index)
          post :create, params: { item_id: pid, wf: 'accessionWF' }
          expect(workflow_client).to have_received(:create_workflow_by_name).with(pid, 'accessionWF')
        end
      end

      context 'when the workflow is already active' do
        let(:wf_response) { instance_double(Dor::Workflow::Response::Workflow, active_for?: true) }

        it 'does not initialize the workflow' do
          post :create, params: { item_id: pid, wf: 'accessionWF' }
          expect(workflow_client).not_to have_received(:create_workflow_by_name)
        end
      end
    end
  end

  describe '#show' do
    let(:workflow) { instance_double(Dor::Workflow::Document) }
    let(:workflow_status) { instance_double(WorkflowStatus) }
    let(:template_response) { { 'processes' => workflow_steps } }
    let(:workflow_steps) do
      [
        { 'name' => 'start-accession' },
        { 'name' => 'descriptive-metadata' },
        { 'name' => 'rights-metadata' },
        { 'name' => 'content-metadata' },
        { 'name' => 'technical-metadata' },
        { 'name' => 'remediate-object' },
        { 'name' => 'shelve' },
        { 'name' => 'published' },
        { 'name' => 'provenance-metadata' },
        { 'name' => 'sdr-ingest-transfer' },
        { 'name' => 'sdr-ingest-received' },
        { 'name' => 'reset-workspace' },
        { 'name' => 'end-accession' }
      ]
    end

    let(:workflow_client) do
      instance_double(Dor::Workflow::Client,
                      workflow: wf_response,
                      workflow_template: template_response)
    end

    context 'when the user wants a table view' do
      let(:presenter) { instance_double(WorkflowPresenter) }
      let(:wf_response) { instance_double(Dor::Workflow::Response::Workflow) }

      it 'requires workflow and repo parameters' do
        expect { get :show, params: { item_id: pid, id: 'accessionWF' } }.to raise_error(ActionController::ParameterMissing)
      end

      it 'fetches the workflow on valid parameters' do
        allow(WorkflowPresenter).to receive(:new).and_return(presenter)
        allow(WorkflowStatus).to receive(:new).and_return(workflow_status)

        get :show, params: { item_id: pid, id: 'accessionWF', repo: 'dor', format: :html }
        expect(response).to have_http_status(:ok)
        expect(WorkflowStatus).to have_received(:new)
          .with(workflow_steps: workflow_steps.map { |item| item['name'] }, workflow: wf_response)
        expect(WorkflowPresenter).to have_received(:new).with(view: Object, workflow_status: workflow_status)
        expect(assigns[:presenter]).to eq presenter
      end

      it 'returns 404 on missing item' do
        expect(Dor).to receive(:find).with(pid).and_raise(ActiveFedora::ObjectNotFoundError)
        get :show, params: { item_id: pid, id: 'accessionWF', repo: 'dor', format: :html }
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when the user wants to see the xml' do
      let(:presenter) { instance_double(WorkflowXmlPresenter) }
      let(:wf_response) { instance_double(Dor::Workflow::Response::Workflow, xml: 'xml') }

      before do
        allow(WorkflowXmlPresenter).to receive(:new).and_return(presenter)
      end

      it 'fetches the workflow on valid parameters' do
        get :show, params: { item_id: pid, id: 'accessionWF', repo: 'dor', raw: true, format: :html }
        expect(response).to have_http_status(:ok)
        expect(WorkflowXmlPresenter).to have_received(:new).with(xml: 'xml')
        expect(assigns[:presenter]).to eq presenter
      end
    end
  end

  describe '#history' do
    let(:xml) { instance_double(String) }
    let(:workflow_client) do
      instance_double(Dor::Workflow::Client,
                      all_workflows_xml: xml)
    end

    it 'fetches the workflow history' do
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
    let(:workflow_client) do
      instance_double(Dor::Workflow::Client,
                      workflow_status: nil,
                      update_status: nil)
    end

    before do
      allow(controller).to receive(:authorize!).and_return(true)
    end

    it 'requires various workflow parameters' do
      expect { post :update, params: { item_id: pid, repo: 'dor', id: 'accessionWF' } }.to raise_error(ActionController::ParameterMissing)
    end

    it 'changes the status' do
      post :update, params: { item_id: pid, id: 'accessionWF', repo: 'dor', process: 'publish', status: 'ready' }
      expect(controller).to have_received(:authorize!).with(:update, :workflow)
      expect(subject).to redirect_to(solr_document_path(pid))
      expect(workflow_client).to have_received(:workflow_status).with('dor', pid, 'accessionWF', 'publish')
      expect(workflow_client).to have_received(:update_status).with(druid: pid, workflow: 'accessionWF', process: 'publish', status: 'ready')
    end
  end
end
