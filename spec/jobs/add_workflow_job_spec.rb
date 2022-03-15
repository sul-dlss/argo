# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AddWorkflowJob, type: :job do
  let(:pids) { ['druid:bb111cc2222', 'druid:cc111dd2222'] }
  let(:groups) { [] }
  let(:bulk_action) { create(:bulk_action) }
  let(:user) { bulk_action.user }

  let(:cocina1) do
    Cocina::Models.build({
                           'label' => 'My Item',
                           'version' => 2,
                           'type' => Cocina::Models::ObjectType.object,
                           'externalIdentifier' => pids[0],
                           'access' => {},
                           'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
                           'description' => { title: [{ value: 'Stored title' }], purl: 'https://purl.stanford.edu/bb111cc2222' },
                           'structural' => {}
                         })
  end
  let(:cocina2) do
    Cocina::Models.build({
                           'label' => 'My Item',
                           'version' => 3,
                           'type' => Cocina::Models::ObjectType.object,
                           'externalIdentifier' => pids[1],
                           'access' => {},
                           'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
                           'description' => { title: [{ value: 'Stored title' }], purl: 'https://purl.stanford.edu/cc111dd2222' },
                           'structural' => {}
                         })
  end

  let(:object_client1) { instance_double(Dor::Services::Client::Object, find: cocina1) }
  let(:object_client2) { instance_double(Dor::Services::Client::Object, find: cocina2) }
  let(:logger) { double('logger', puts: nil) }
  let(:wf_client) { instance_double(Dor::Workflow::Client, create_workflow_by_name: true, workflow: wf_response) }
  let(:wf_response) { instance_double(Dor::Workflow::Response::Workflow, active_for?: active) }
  let(:active) { false }

  before do
    allow(WorkflowClientFactory).to receive(:build).and_return(wf_client)
    allow(Ability).to receive(:new).and_return(ability)
    allow(Dor::Services::Client).to receive(:object).with(pids[0]).and_return(object_client1)
    allow(Dor::Services::Client).to receive(:object).with(pids[1]).and_return(object_client2)
    allow(BulkJobLog).to receive(:open).and_yield(logger)

    described_class.perform_now(bulk_action.id,
                                pids: pids,
                                add_workflow: { workflow: 'accessionWF' },
                                groups: groups,
                                user: user)
  end

  context 'with manage ability' do
    let(:ability) { instance_double(Ability, can?: true) }

    context 'when the workflow already exists' do
      let(:active) { true }

      it 'does not create a workflow' do
        expect(logger).to have_received(:puts).with(/Starting AddWorkflowJob for BulkAction/)
        expect(logger).to have_received(:puts).with(/accessionWF already exists for druid:bb111cc2222/)
        expect(logger).to have_received(:puts).with(/accessionWF already exists for druid:cc111dd2222/)

        expect(wf_client).not_to have_received(:create_workflow_by_name)
      end
    end

    context "when the workflow doesn't exist" do
      it 'creates a workflow' do
        expect(logger).to have_received(:puts).with(/Starting AddWorkflowJob for BulkAction/)
        expect(logger).to have_received(:puts).with(/started accessionWF for druid:bb111cc2222/)
        expect(logger).to have_received(:puts).with(/started accessionWF for druid:bb111cc2222/)

        expect(wf_client).to have_received(:create_workflow_by_name).twice
      end
    end
  end

  context 'without manage ability' do
    let(:ability) { instance_double(Ability, can?: false) }

    it 'does not create a workflow' do
      expect(logger).to have_received(:puts).with(/Starting AddWorkflowJob for BulkAction/)
      expect(logger).to have_received(:puts).with(/Not authorized for druid:cc111dd2222/)
      expect(logger).to have_received(:puts).with(/Not authorized for druid:cc111dd2222/)
      expect(wf_client).not_to have_received(:create_workflow_by_name)
    end
  end
end