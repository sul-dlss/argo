# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'WorkflowsController', type: :request do
  let(:pid) { 'druid:bc123df4567' }
  let(:user) { create(:user) }
  let(:workflow_client) { instance_double(Dor::Workflow::Client) }

  let(:rendered) do
    Capybara::Node::Simple.new(response.body)
  end

  let(:cocina) do
    Cocina::Models.build({
                           'label' => 'My Item',
                           'version' => 2,
                           'type' => Cocina::Models::ObjectType.object,
                           'externalIdentifier' => pid,
                           'description' => {
                             'title' => [{ 'value' => 'My Item' }],
                             'purl' => "https://purl.stanford.edu/#{pid.delete_prefix('druid:')}"
                           },
                           'access' => {},
                           'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
                           'structural' => {},
                           'identification' => {}
                         })
  end

  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina) }

  before do
    sign_in user
    allow(Dor::Workflow::Client).to receive(:new).and_return(workflow_client)
    allow(Dor::Services::Client).to receive(:object).with(pid).and_return(object_client)
  end

  describe '#create' do
    context 'when they have manage access' do
      let(:workflow_client) do
        instance_double(Dor::Workflow::Client,
                        create_workflow_by_name: true,
                        workflow: wf_response)
      end

      before do
        allow(Argo::Indexer).to receive(:reindex_pid_remotely)
      end

      context 'when the workflow is not active' do
        let(:wf_response) { instance_double(Dor::Workflow::Response::Workflow, active_for?: false) }

        it 'initializes the new workflow' do
          post "/items/#{pid}/workflows", params: { wf: 'accessionWF' }

          expect(workflow_client).to have_received(:create_workflow_by_name)
            .with(pid, 'accessionWF', version: 2)
        end
      end

      context 'when the workflow is already active' do
        let(:wf_response) { instance_double(Dor::Workflow::Response::Workflow, active_for?: true) }

        it 'does not initialize the workflow' do
          post "/items/#{pid}/workflows", params: { wf: 'accessionWF' }

          expect(workflow_client).not_to have_received(:create_workflow_by_name)
        end
      end
    end
  end

  describe '#new' do
    let(:workflow_client) { instance_double(Dor::Workflow::Client, workflow_templates: ['accessionWF']) }

    it 'renders the template with no layout' do
      get "/items/#{pid}/workflows/new"
      expect(response.body).to start_with('<turbo-frame')
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
      let(:process) do
        instance_double(Dor::Workflow::Response::Process,
                        name: 'start-accession',
                        status: 'waiting',
                        datetime: Time.zone.now,
                        elapsed: 10,
                        attempts: 1,
                        lifecycle: nil,
                        note: nil)
      end
      let(:wf_response) do
        instance_double(Dor::Workflow::Response::Workflow,
                        pid: pid,
                        workflow_name: 'accessionWF',
                        empty?: false,
                        process_for_recent_version: process)
      end

      it 'fetches the workflow on valid parameters' do
        get "/items/#{pid}/workflows/accessionWF"

        expect(response).to have_http_status(:ok)
        expect(rendered.find_css('.detail > tbody > tr').size).to eq workflow_steps.count
      end
    end

    context 'when the user wants to see the xml' do
      let(:presenter) { instance_double(WorkflowXmlPresenter, pretty_xml: '<xml/>') }
      let(:wf_response) { instance_double(Dor::Workflow::Response::Workflow, xml: 'xml') }

      before do
        allow(WorkflowXmlPresenter).to receive(:new).and_return(presenter)
      end

      it 'fetches the workflow on valid parameters' do
        get "/items/#{pid}/workflows/accessionWF?raw=true"

        expect(response).to have_http_status(:ok)
        expect(WorkflowXmlPresenter).to have_received(:new).with(xml: 'xml')
        expect(response.body).to include ' &lt;xml/&gt;'
      end
    end
  end

  describe '#history' do
    let(:xml) { '<xml/>' }
    let(:workflows) { instance_double(Dor::Workflow::Response::Workflows, xml: xml) }
    let(:workflow_routes) { instance_double(Dor::Workflow::Client::WorkflowRoutes, all_workflows: workflows) }
    let(:workflow_client) do
      instance_double(Dor::Workflow::Client, workflow_routes: workflow_routes)
    end

    it 'fetches the workflow history' do
      get "/items/#{pid}/workflows/history"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include '<span style="color:#070;font-weight:bold">&lt;xml</span><span style="color:#070;font-weight:bold">/&gt;</span>'
    end
  end

  describe '#update' do
    let(:workflow_client) do
      instance_double(Dor::Workflow::Client,
                      workflow_status: nil,
                      update_status: nil)
    end

    it 'requires various workflow parameters' do
      expect { put "/items/#{pid}/workflows/accessionWF" }.to raise_error(ActionController::ParameterMissing)
    end

    context 'when the user is an administrator' do
      before do
        sign_in build(:user), groups: ['sdr:administrator-role']
      end

      it 'changes the status' do
        put "/items/#{pid}/workflows/accessionWF", params: { process: 'publish', status: 'completed' }
        expect(subject).to redirect_to(solr_document_path(pid))
        expect(workflow_client).to have_received(:workflow_status).with(druid: pid, workflow: 'accessionWF', process: 'publish')
        expect(workflow_client).to have_received(:update_status).with(druid: pid, workflow: 'accessionWF', process: 'publish', status: 'completed')
      end
    end

    context 'when the user is not an administrator' do
      before do
        sign_in build(:user), groups: []
      end

      context 'when they are changing an item they do not manage' do
        it 'is forbidden' do
          put "/items/#{pid}/workflows/accessionWF", params: { process: 'publish', status: 'waiting' }

          expect(response.status).to eq 403
          expect(workflow_client).not_to have_received(:update_status)
        end
      end
    end
  end
end
