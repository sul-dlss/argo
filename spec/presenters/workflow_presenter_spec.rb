# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkflowPresenter do
  subject(:presenter) do
    described_class.new(view: stub_view, workflow_status: workflow_status)
  end

  let(:stub_view) { double('view') }
  let(:workflow_status) { instance_double(WorkflowStatus, process_statuses: process_statuses) }
  let(:workflow_name) { 'accessionWF' }

  let(:pid) { 'druid:oo201oo0001' }
  let(:item) { Dor::Item.new pid: pid }

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
        expect(subject.size).to eq 3
        expect(subject).to all(be_kind_of WorkflowProcessPresenter)
      end
    end
  end
end
