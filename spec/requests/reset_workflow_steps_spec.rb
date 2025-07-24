# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Reset failed workflow steps' do
  let(:blacklight_config) { CatalogController.blacklight_config }
  let(:solr_conn) { blacklight_config.repository_class.new(blacklight_config).connection }

  let(:user) { create(:user) }

  let(:workflow) { 'accessionWF' }
  let(:step) { 'descriptive-metadata' }
  let(:process_client) { instance_double(Dor::Services::Client::Process, update: true) }
  let(:workflow_client) { instance_double(Dor::Services::Client::ObjectWorkflow, process: process_client) }
  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model, workflow: workflow_client) }
  let(:druid) { 'druid:xb482bw3979' }
  let(:cocina_model) { build(:dro_with_metadata) }

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
  end

  context 'as an admin' do
    let(:report) { instance_double(Report, druids: %w[xb482ww9999]) }

    before do
      sign_in user, groups: ['sdr:administrator-role']
      allow(Report).to receive(:new).and_return(report)
    end

    it 'calls update workflow service' do
      post '/report/reset', params: { reset_workflow: workflow, reset_step: step, q: 'Cephalopods' } # has single match
      expect(response).to redirect_to(report_workflow_grid_path)
      expect(object_client).to have_received(:workflow).with(workflow)
      expect(workflow_client).to have_received(:process).with(step)
      expect(process_client).to have_received(:update).with(status: 'waiting', current_status: 'error')
    end

    it 'requires parameters' do
      post '/report/reset'
      expect(response).to have_http_status(:bad_request)

      post '/report/reset', params: { reset_workflow: workflow }
      expect(response).to have_http_status(:bad_request)

      post '/report/reset', params: { reset_step: step }
      expect(response).to have_http_status(:bad_request)
    end
  end

  context 'as a non admin with access' do
    let(:report) { instance_double(Report, druids: %w[xb482ww9999]) }

    before do
      sign_in user, groups: ['sdr:manager-role']
      allow(Report).to receive(:new).and_return(report)
    end

    it 'calls update workflow service' do
      post '/report/reset', params: { reset_workflow: workflow, reset_step: step, q: 'Cephalopods' } # has single match

      expect(response).to redirect_to(report_workflow_grid_path)
      expect(process_client).to have_received(:update).with(status: 'waiting', current_status: 'error')
    end
  end

  context 'as a non admin without access' do
    let(:report) { instance_double(Report, druids: %w[xb482ww9999]) }

    before do
      sign_in user, groups: []

      allow(Report).to receive(:new).and_return(report)
    end

    it 'does not call update workflow service' do
      post '/report/reset', params: { reset_workflow: workflow, reset_step: step, q: 'Cephalopods' } # has single match

      expect(response).to redirect_to(report_workflow_grid_path)
      expect(process_client).not_to have_received(:update)
    end
  end
end
