# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'WorkflowsController' do
  let(:druid) { 'druid:bc123df4567' }
  let(:user) { create(:user) }

  let(:rendered) do
    Capybara::Node::Simple.new(response.body)
  end

  let(:cocina) { build(:dro_with_metadata, id: druid, version: 2) }
  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina, workflow: workflow_client) }
  let(:workflow_client) { instance_double(Dor::Services::Client::ObjectWorkflow, create: true, find: wf_response) }
  let(:wf_response) { instance_double(Dor::Services::Response::Workflow) }

  before do
    sign_in user
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
  end

  describe '#create' do
    context 'when they have manage access' do
      context 'when the workflow is not active' do
        before do
          allow(WorkflowService).to receive(:workflow_active?).and_return(false)
        end

        it 'initializes the new workflow' do
          post "/items/#{druid}/workflows", params: { wf: 'accessionWF' }

          expect(workflow_client).to have_received(:create).with(version: 2)
          expect(object_client).to have_received(:workflow).with('accessionWF')
        end
      end

      context 'when the workflow is already active' do
        before do
          allow(WorkflowService).to receive(:workflow_active?).and_return(true)
        end

        it 'does not initialize the workflow' do
          post "/items/#{druid}/workflows", params: { wf: 'accessionWF' }

          expect(workflow_client).not_to have_received(:create)
          expect(response).to redirect_to(solr_document_path(druid))
          expect(flash[:error]).to eq 'accessionWF already exists!'
        end
      end
    end
  end

  describe '#new' do
    it 'renders the template with no layout' do
      get "/items/#{druid}/workflows/new"
      expect(response.body).to start_with('<turbo-frame')
    end
  end

  describe '#show' do
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
    let(:workflows_client) { instance_double(Dor::Services::Client::Workflows) }

    before do
      allow(Dor::Services::Client).to receive(:workflows).and_return(workflows_client)
      allow(workflows_client).to receive(:template).with('accessionWF').and_return(template_response)
    end

    context 'when the user wants a table view' do
      let(:wf_response) do
        instance_double(Dor::Services::Response::Workflow,
                        pid: druid,
                        workflow_name: 'accessionWF',
                        empty?: false,
                        process_for_recent_version: process)
      end
      let(:process) do
        instance_double(Dor::Services::Response::Process,
                        name: 'start-accession',
                        status: 'waiting',
                        datetime: Time.zone.now,
                        elapsed: 10,
                        attempts: 1,
                        lifecycle: nil,
                        context:,
                        note: nil)
      end

      context 'when there is no workflow context' do
        let(:context) { nil }

        it 'fetches the workflow on valid parameters and does not show any context' do
          get "/items/#{druid}/workflows/accessionWF"

          expect(response).to have_http_status(:ok)
          expect(rendered.find_css('.detail > tbody > tr').size).to eq workflow_steps.count
          expect(rendered.find_css('#workflow-context').size).to eq 0
        end
      end

      context 'when there is workflow context' do
        let(:context) { { 'requireOCR' => true } }

        it 'fetches the workflow on valid parameters and shows the context' do
          get "/items/#{druid}/workflows/accessionWF"

          expect(response).to have_http_status(:ok)
          expect(rendered.find_css('.detail > tbody > tr').size).to eq workflow_steps.count
          expect(rendered.find_css('#workflow-context').size).to eq 1
          expect(response.body).to include '<td>requireOCR</td>'
          expect(response.body).to include '<td>true</td>'
        end
      end
    end

    context 'when the user wants to see the xml' do
      let(:presenter) { instance_double(WorkflowXmlPresenter, pretty_xml: '<xml/>') }
      let(:wf_response) { instance_double(Dor::Workflow::Response::Workflow, xml: 'xml') }

      before do
        allow(WorkflowXmlPresenter).to receive(:new).and_return(presenter)
      end

      it 'fetches the workflow on valid parameters' do
        get "/items/#{druid}/workflows/accessionWF?raw=true"

        expect(response).to have_http_status(:ok)
        expect(WorkflowXmlPresenter).to have_received(:new).with(xml: 'xml')
        expect(response.body).to include ' &lt;xml/&gt;'
      end
    end
  end

  describe '#history' do
    let(:xml) { Nokogiri::XML('<xml/>') }
    let(:workflows) { instance_double(Dor::Services::Response::Workflows, xml:) }

    before do
      allow(object_client).to receive(:workflows).and_return(workflows)
    end

    it 'fetches the workflow history' do
      get "/items/#{druid}/workflows/history"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include '<span style="color:#070;font-weight:bold">&lt;xml</span><span style="color:#070;font-weight:bold">/&gt;</span>'
    end
  end

  describe '#update' do
    let(:process_client) { instance_double(Dor::Services::Client::Process, update: true, status: 'waiting') }

    before do
      allow(workflow_client).to receive(:process).with('publish').and_return(process_client)
    end

    it 'requires various workflow parameters' do
      put "/items/#{druid}/workflows/accessionWF"
      expect(response).to have_http_status(:bad_request)
    end

    context 'when the user is an administrator' do
      before do
        sign_in build(:user), groups: ['sdr:administrator-role']
      end

      it 'changes the status' do
        put "/items/#{druid}/workflows/accessionWF", params: { process: 'publish', status: 'completed' }
        expect(subject).to redirect_to(solr_document_path(druid))
        expect(process_client).to have_received(:update).with(status: 'completed')
      end
    end

    context 'when the user is not an administrator' do
      before do
        sign_in build(:user), groups: []
      end

      context 'when they are changing an item they do not manage' do
        it 'is forbidden' do
          put "/items/#{druid}/workflows/accessionWF", params: { process: 'publish', status: 'waiting' }

          expect(response).to have_http_status :forbidden
          expect(process_client).not_to have_received(:update)
        end
      end
    end
  end
end
