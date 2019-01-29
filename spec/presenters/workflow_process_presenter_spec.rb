# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkflowProcessPresenter do
  subject(:instance) { described_class.new(name: 'accessionWF', **attributes) }

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
end
