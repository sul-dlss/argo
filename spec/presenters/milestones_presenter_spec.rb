# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MilestonesPresenter do
  subject(:presenter) do
    described_class.new(milestones: milestones, versions: versions)
  end

  let(:milestones) { {} }
  let(:versions) { ['1;1.0.0;Initial version', '2;1.1.0;Minor change'] }

  describe '#version_title' do
    subject { presenter.version_title(version) }

    context 'when the version is 1' do
      let(:version) { '1' }

      it { is_expected.to eq '1 (1.0.0) Initial version' }
    end

    context 'when the version is 2' do
      let(:version) { '2' }

      it { is_expected.to eq '2 (1.1.0) Minor change' }
    end
  end
end
