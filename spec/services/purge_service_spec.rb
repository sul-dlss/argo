# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PurgeService do
  describe '.purge' do
    subject(:purge) { described_class.purge(druid: 'druid:ab123cd4567') }

    let(:object_client) { instance_double(Dor::Services::Client::Object, destroy: true) }
    let(:workflow_client) { instance_double(Dor::Workflow::Client, delete_all_workflows: true) }
    let(:solr_client) { instance_double(RSolr::Client, delete_by_id: true, commit: true) }
    let(:repo) { instance_double(Blacklight::Solr::Repository, connection: solr_client) }

    before do
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
      allow(WorkflowClientFactory).to receive(:build).and_return(workflow_client)
      allow(Blacklight::Solr::Repository).to receive(:new).and_return(repo)
    end

    it 'removes the object' do
      purge
      expect(object_client).to have_received(:destroy)
      expect(workflow_client).to have_received(:delete_all_workflows)
      expect(solr_client).to have_received(:delete_by_id)
      expect(solr_client).to have_received(:commit)
    end
  end
end
