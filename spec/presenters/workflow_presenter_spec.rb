# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkflowPresenter do
  subject(:presenter) do
    described_class.new(view: stub_view, workflow_status: workflow_status, item: item)
  end

  let(:stub_view) { double('view') }
  let(:workflow_status) { instance_double(WorkflowStatus, process_statuses: process_statuses) }
  let(:workflow_name) { 'accessionWF' }
  let(:item) { build(:item) }

  describe '#processes' do
    subject { presenter.processes }

    context 'when the data has no processes' do
      let(:process_statuses) do
        []
      end

      it 'has none' do
        expect(subject).to be_empty
      end
    end

    context 'when the data has processes' do
      let(:process_statuses) do
        [
          instance_double(Dor::Workflow::Response::Process, name: 'start-accession'),
          instance_double(Dor::Workflow::Response::Process, name: 'descriptive-metadata'),
          instance_double(Dor::Workflow::Response::Process, name: 'rights-metadata')
        ]
      end

      it 'has one for each xml process' do
        expect(subject).to eq process_statuses
      end
    end
  end
end
