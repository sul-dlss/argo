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
      expect(controller).to receive(:fetch_workflow).and_return(workflow)
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

  describe '#fetch_workflow' do
    subject(:fetch_workflow) { controller.send(:fetch_workflow, pid, 'accessionWF', 'dor') }

    before do
      allow(Dor::Config.workflow.client).to receive(:get_workflow_xml).and_return(xml)
    end

    context 'when there is xml' do
      let(:xml) do
        '<?xml version="1.0" encoding="UTF-8"?>
          <workflow repository="dor" objectId="druid:oo201oo0001" id="accessionWF">
            <process version="2" lifecycle="submitted" elapsed="0.0" archived="true" attempts="1"
              datetime="2012-11-06T16:18:24-0800" status="completed" name="start-accession"/>
            <process version="2" elapsed="0.0" archived="true" attempts="1"
              datetime="2012-11-06T16:18:58-0800" status="completed" name="technical-metadata"/>
            <process version="2" elapsed="0.0" archived="true" attempts="1"
              datetime="2012-11-06T16:19:02-0800" status="completed" name="provenance-metadata"/>
            <process version="2" elapsed="0.0" archived="true" attempts="1"
              datetime="2012-11-06T16:19:05-0800" status="completed" name="remediate-object"/>
            <process version="2" elapsed="0.0" archived="true" attempts="1"
              datetime="2012-11-06T16:19:06-0800" status="completed" name="shelve"/>
            <process version="2" lifecycle="published" elapsed="0.0" archived="true" attempts="1"
              datetime="2012-11-06T16:19:07-0800" status="completed" name="publish"/>
            <process version="2" elapsed="0.0" archived="true" attempts="1"
              datetime="2012-11-06T16:19:09-0800" status="completed" name="sdr-ingest-transfer"/>
            <process version="2" lifecycle="accessioned" elapsed="0.0" archived="true" attempts="1"
              datetime="2012-11-06T16:19:10-0800" status="completed" name="cleanup"/>
            <process version="2" elapsed="0.0" archived="true" attempts="1"
              datetime="2012-11-06T16:19:13-0800" status="completed" name="rights-metadata"/>
            <process version="2" lifecycle="described" elapsed="0.0" archived="true" attempts="1"
              datetime="2012-11-06T16:19:15-0800" status="completed" name="descriptive-metadata"/>
            <process version="2" elapsed="0.0" archived="true" attempts="2"
              datetime="2012-11-06T16:19:16-0800" status="completed" name="content-metadata"/>'
      end

      it { is_expected.to be_kind_of Dor::Workflow::Document }
    end

    context 'when the xml is empty' do
      let(:xml) { '' }

      it { is_expected.to be_nil }
    end
  end
end
