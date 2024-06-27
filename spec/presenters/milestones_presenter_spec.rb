# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MilestonesPresenter do
  subject(:presenter) do
    described_class.new(druid: 'druid:mk420bs7601')
  end

  let(:milestone2) do
    {
      'opened' => { time: '2020-05-04 18:24:14 +0000' },
      'submitted' => { time: '2020-05-04 18:24:15 +0000' },
      'published' => { time: '2020-05-04 18:24:15 +0000' },
      'deposited' => { time: '2020-05-04 18:24:15 +0000' },
      'accessioned' => { time: '2020-05-04 18:24:15 +0000' }
    }
  end

  let(:milestones) do
    { '1' => {
      'registered' => { time: '2020-03-02 13:12:43 +0000' },
      'submitted' => { time: '2020-05-01 19:26:37 +0000' },
      'published' => { time: '2020-05-01 19:26:37 +0000' },
      'deposited' => { time: '2020-05-01 19:26:37 +0000' },
      'accessioned' => { time: '2020-05-01 19:26:37 +0000' }
    }, '2' => milestone2 }
  end

  let(:versions) do
    [
      Dor::Services::Client::ObjectVersion::Version.new(versionId: 1, message: 'Initial version'),
      Dor::Services::Client::ObjectVersion::Version.new(versionId: 2, message: 'Minor change')
    ]
  end

  let(:user_versions) do
    [
      Dor::Services::Client::UserVersion::Version.new(version: 2, userVersion: 1)
    ]
  end

  before do
    allow(MilestoneService).to receive(:milestones_for).and_return(milestones)
    allow(Dor::Services::Client).to receive_message_chain(:object, :version, :inventory).and_return(versions) # rubocop:disable RSpec/MessageChain
    allow(Dor::Services::Client).to receive_message_chain(:object, :user_version, :inventory).and_return(user_versions) # rubocop:disable RSpec/MessageChain
  end

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

      it { is_expected.to eq '1 Initial version' }
    end

    context 'when the version is 2' do
      let(:version) { '2' }

      it { is_expected.to eq '2 Minor change' }
    end
  end

  describe '#steps_for' do
    subject { presenter.steps_for('2') }

    it { is_expected.to eq milestone2 }
  end

  describe '#user_version_for' do
    subject { presenter.user_version_for('2') }

    it { is_expected.to eq 1 }
  end
end
