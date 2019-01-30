# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkflowProcessPresenter do
  subject(:instance) do
    described_class.new(view: stub_view,
                        pid: 'druid:123',
                        workflow_name: 'start-accession',
                        name: 'accessionWF',
                        **attributes)
  end

  let(:stub_view) { double('view') }

  let(:attributes) { {} }

  describe '#elapsed' do
    subject { instance.elapsed }

    context 'for nil' do
      it { is_expected.to be_nil }
    end

    context 'for empty string' do
      let(:attributes) { { elapsed: '' } }

      it { is_expected.to eq '0.000' }
    end

    context 'for a float' do
      let(:attributes) { { elapsed: '2.257' } }

      it { is_expected.to eq '2.257' }
    end
  end

  describe '#note' do
    subject { instance.note }

    context 'for nil' do
      it { is_expected.to be_nil }
    end

    context 'for empty string' do
      let(:attributes) { { note: '' } }

      it { is_expected.to be_nil }
    end

    context 'for a value' do
      let(:attributes) { { note: 'hi' } }

      it { is_expected.to eq 'hi' }
    end
  end
end
