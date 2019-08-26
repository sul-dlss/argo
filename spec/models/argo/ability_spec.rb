# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Argo::Ability do
  subject(:ability) { described_class }

  describe 'can_manage_items?' do
    subject { ability.can_manage_items?(groups) }

    context 'when the group has rights' do
      let(:groups) { %w[sdr-administrator] }

      it { is_expected.to be true }
    end

    context "when the group doesn't have rights" do
      let(:groups) { %w[sdr-apo-metadata] }

      it { is_expected.to be false }
    end
  end

  describe 'can_edit_desc_metadata?' do
    subject { ability.can_edit_desc_metadata?(groups) }

    context 'when the group has rights' do
      let(:groups) { %w[dor-apo-metadata] }

      it { is_expected.to be true }
    end

    context "when the group doesn't have rights" do
      let(:groups) { %w[dor-viewer] }

      it { is_expected.to be false }
    end
  end

  describe 'can_view?' do
    subject { ability.can_view?(groups) }

    context 'when the group has rights' do
      let(:groups) { %w[dor-viewer] }

      it { is_expected.to be true }
    end

    context "when the group doesn't have rights" do
      let(:groups) { %w[dor-people] }

      it { is_expected.to be false }
    end
  end
end
