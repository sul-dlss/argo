# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AddWorkflowJob do
  let(:druids) { ['druid:bb111cc2222', 'druid:cc111dd2222'] }
  let(:groups) { [] }
  let(:bulk_action) { create(:bulk_action) }
  let(:user) { bulk_action.user }
  let(:cocina1) do
    build(:dro_with_metadata, id: druids[0])
  end
  let(:cocina2) do
    build(:dro_with_metadata, id: druids[1])
  end
  let(:object_client1) { instance_double(Dor::Services::Client::Object, find: cocina1, workflow: wf_client) }
  let(:object_client2) { instance_double(Dor::Services::Client::Object, find: cocina2, workflow: wf_client) }
  let(:logger) { double('logger', puts: nil) }
  let(:wf_client) { instance_double(Dor::Services::Client::ObjectWorkflow, create: true, find: wf_response) }
  let(:wf_response) { instance_double(Dor::Services::Response::Workflow, active_for?: active) }
  let(:active) { false }

  before do
    allow(Ability).to receive(:new).and_return(ability)
    allow(Dor::Services::Client).to receive(:object).with(druids[0]).and_return(object_client1)
    allow(Dor::Services::Client).to receive(:object).with(druids[1]).and_return(object_client2)
    allow(VersionService).to receive(:open?).with(druid: druids[0]).and_return(true)
    allow(VersionService).to receive(:open?).with(druid: druids[1]).and_return(false)
    allow(VersionService).to receive(:openable?).with(druid: druids[1]).and_return(true)
    allow(VersionService).to receive(:open).and_return(cocina2)
    allow(BulkJobLog).to receive(:open).and_yield(logger)

    described_class.perform_now(bulk_action.id,
                                druids:,
                                workflow: 'accessionWF',
                                groups:,
                                user:)
  end

  context 'with manage ability' do
    let(:ability) { instance_double(Ability, can?: true) }

    context 'when the workflow already exists' do
      let(:active) { true }

      it 'does not create a workflow' do
        expect(logger).to have_received(:puts).with(/Starting AddWorkflowJob for BulkAction/)
        expect(logger).to have_received(:puts).with(/accessionWF already exists for druid:bb111cc2222/)
        expect(logger).to have_received(:puts).with(/accessionWF already exists for druid:cc111dd2222/)

        expect(wf_client).not_to have_received(:create)
      end
    end

    context "when the workflow doesn't exist" do
      it 'creates a workflow' do
        expect(logger).to have_received(:puts).with(/Starting AddWorkflowJob for BulkAction/)
        expect(logger).to have_received(:puts).with(/started accessionWF for druid:bb111cc2222/)
        expect(logger).to have_received(:puts).with(/started accessionWF for druid:bb111cc2222/)

        expect(wf_client).to have_received(:create).twice
        expect(VersionService).to have_received(:open)
          .with(druid: druids[1], description: 'Running accessionWF', opening_user_name: bulk_action.user.to_s)
      end
    end
  end

  context 'without manage ability' do
    let(:ability) { instance_double(Ability, can?: false) }

    it 'does not create a workflow' do
      expect(logger).to have_received(:puts).with(/Starting AddWorkflowJob for BulkAction/)
      expect(logger).to have_received(:puts).with(/Not authorized for druid:cc111dd2222/)
      expect(logger).to have_received(:puts).with(/Not authorized for druid:cc111dd2222/)
      expect(wf_client).not_to have_received(:create)
    end
  end
end
