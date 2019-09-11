# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkflowProcessPresenter, type: :view do
  subject(:instance) { described_class.new(view: view, process_status: process_status) }

  describe '#elapsed' do
    subject { instance.elapsed }

    context 'for nil' do
      let(:process_status) { instance_double(Dor::Workflow::Response::Process, elapsed: nil) }

      it { is_expected.to be_nil }
    end

    context 'for empty string' do
      let(:process_status) { instance_double(Dor::Workflow::Response::Process, elapsed: '') }

      it { is_expected.to eq '0.000' }
    end

    context 'for a float' do
      let(:process_status) { instance_double(Dor::Workflow::Response::Process, elapsed: '2.25743') }

      it { is_expected.to eq '2.257' }
    end
  end

  describe '#note' do
    subject { instance.note }

    let(:process_status) { instance_double(Dor::Workflow::Response::Process, note: 'hi') }

    it { is_expected.to eq 'hi' }
  end

  describe '#error_message' do
    subject { instance.error_message }

    let(:process_status) { instance_double(Dor::Workflow::Response::Process, error_message: "it's a bad day") }

    it { is_expected.to eq "it's a bad day" }
  end

  describe '#status_action' do
    subject { instance.status_action }

    let(:process_status) do
      instance_double(Dor::Workflow::Response::Process,
                      status: status,
                      pid: 'druid:132',
                      workflow_name: 'accessionWF',
                      name: 'technical-metadata')
    end

    context "when it's not an allowable change" do
      let(:status) { 'queued' }

      it { is_expected.to be_nil }
    end

    context "when it's in waiting" do
      let(:status) { 'waiting' }

      it { is_expected.to have_button 'Set to completed' }
      it { is_expected.to have_css 'input[name="_method"][value="put"]', visible: false }
    end

    context "when it's in error" do
      let(:status) { 'error' }

      it { is_expected.to have_select 'status', options: %w[Select Rerun Skip Complete] }
      it { is_expected.to have_css 'input[name="_method"][value="put"]', visible: false }
    end
  end
end
