# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkflowProcessPresenter do
  subject(:instance) { described_class.new(view: stub_view, process_status: process_status) }

  let(:stub_view) { double('view') }

  describe '#elapsed' do
    subject { instance.elapsed }

    context 'for nil' do
      let(:process_status) { instance_double(WorkflowProcessStatus, elapsed: nil) }

      it { is_expected.to be_nil }
    end

    context 'for empty string' do
      let(:process_status) { instance_double(WorkflowProcessStatus, elapsed: '') }

      it { is_expected.to eq '0.000' }
    end

    context 'for a float' do
      let(:process_status) { instance_double(WorkflowProcessStatus, elapsed: '2.25743') }

      it { is_expected.to eq '2.257' }
    end
  end

  describe '#note' do
    subject { instance.note }

    let(:process_status) { instance_double(WorkflowProcessStatus, note: 'hi') }

    it { is_expected.to eq 'hi' }
  end
end
