# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MilestonesPresenter do
  subject(:presenter) do
    described_class.new(milestones: milestones, versions: versions)
  end

  let(:milestone2) do
    {
      'opened' => { time: '2020-05-04 18:24:14 +0000' },
      'submitted' => { time: '2020-05-04 18:24:15 +0000' },
      'described' => { time: '2020-05-04 18:24:15 +0000' },
      'published' => { time: '2020-05-04 18:24:15 +0000' },
      'deposited' => { time: '2020-05-04 18:24:15 +0000' },
      'accessioned' => { time: '2020-05-04 18:24:15 +0000' }
    }
  end

  let(:milestones) do
    { '1' => {
      'registered' => { time: '2020-03-02 13:12:43 +0000' },
      'submitted' => { time: '2020-05-01 19:26:37 +0000' },
      'described' => { time: '2020-05-01 19:26:37 +0000' },
      'published' => { time: '2020-05-01 19:26:37 +0000' },
      'deposited' => { time: '2020-05-01 19:26:37 +0000' },
      'accessioned' => { time: '2020-05-01 19:26:37 +0000' }
    }, '2' => milestone2 }
  end
  let(:versions) { ['1;1.0.0;Initial version', '2;1.1.0;Minor change'] }

  describe '#each_version' do
    let(:actual_versions) do
      versions = []
      presenter.each_version { |version| versions << version }
      versions
    end

    it 'invokes block for each version' do
      expect(actual_versions).to eq %w[1 2]
    end
  end

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

  describe '#steps_for' do
    subject { presenter.steps_for('2') }

    it { is_expected.to eq milestone2 }
  end
end
