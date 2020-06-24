# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HomeTextPresenter do
  let(:user) do
    instance_double(User,
                    admin?: false,
                    manager?: false,
                    viewer?: false,
                    permitted_apos: [])
  end

  let(:instance) { described_class.new(user) }

  describe '#view_something?' do
    subject { instance.view_something? }

    it { is_expected.to be false }

    context 'when admin' do
      before do
        allow(user).to receive(:admin?).and_return(true)
      end

      it { is_expected.to be true }
    end

    context 'when manager' do
      before do
        allow(user).to receive(:manager?).and_return(true)
      end

      it { is_expected.to be true }
    end

    context 'when viewer' do
      before do
        allow(user).to receive(:viewer?).and_return(true)
      end

      it { is_expected.to be true }
    end

    context 'with permitted_apos' do
      before do
        allow(user).to receive(:permitted_apos).and_return([1])
      end

      it { is_expected.to be true }
    end
  end
end
