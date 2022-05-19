# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Reset failed workflow steps', type: :request do
  let(:blacklight_config) { CatalogController.blacklight_config }
  let(:solr_conn) { blacklight_config.repository_class.new(blacklight_config).connection }

  let(:user) { create(:user) }

  let(:workflow) { 'accessionWF' }
  let(:step) { 'descriptive-metadata' }
  let(:workflow_client) { instance_double(Dor::Workflow::Client, update_status: true) }
  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model) }
  let(:druid) { 'druid:xb482bw3979' }
  let(:cocina_model) { build(:dro_with_metadata) }

  before do
    allow(Dor::Workflow::Client).to receive(:new).and_return(workflow_client)
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
      expect(workflow_client).to have_received(:update_status)
        .with(druid: 'druid:xb482ww9999', workflow:, process: step, status: 'waiting', current_status: 'error')
    end

    it 'requires parameters' do
      expect { post '/report/reset' }.to raise_error(ActionController::ParameterMissing)
      expect { post '/report/reset', params: { reset_workflow: workflow } }.to raise_error(ActionController::ParameterMissing)
      expect { post '/report/reset', params: { reset_step: step } }.to raise_error(ActionController::ParameterMissing)
    end
  end

  context 'a non admin who has access' do
    let(:report) { instance_double(Report, druids: %w[xb482ww9999]) }

    before do
      sign_in user, groups: ['sdr:manager-role']
      allow(Report).to receive(:new).and_return(report)
    end

    it 'calls update workflow service' do
      post '/report/reset', params: { reset_workflow: workflow, reset_step: step, q: 'Cephalopods' } # has single match

      expect(response).to redirect_to(report_workflow_grid_path)
      expect(workflow_client).to have_received(:update_status)
        .with(druid: 'druid:xb482ww9999', workflow:, process: step, status: 'waiting', current_status: 'error')
    end
  end

  context 'a non admin who has no access' do
    let(:report) { instance_double(Report, druids: %w[xb482ww9999]) }

    before do
      sign_in user, groups: []

      allow(Report).to receive(:new).and_return(report)
    end

    it 'does not call update workflow service' do
      post '/report/reset', params: { reset_workflow: workflow, reset_step: step, q: 'Cephalopods' } # has single match

      expect(response).to redirect_to(report_workflow_grid_path)
      expect(workflow_client).not_to have_received(:update_status)
    end
  end
end
