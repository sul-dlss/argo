# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserVersionsPresenter do
  subject(:presenter) do
    described_class.new(user_version:, user_version_inventory:)
  end

  let(:user_version) { '1' }
  let(:user_version_inventory) do
    [
      Dor::Services::Client::UserVersion::Version.new(userVersion: '1', version: '3', withdrawable: false, restorable: true),
      Dor::Services::Client::UserVersion::Version.new(userVersion: '2', version: '4', withdrawable: true, restorable: false)
    ]
  end

  describe '#user_version_for' do
    subject { presenter.user_version_for(version) }

    context 'when the version is found' do
      let(:version) { '3' }

      it { is_expected.to eq '1' }
    end

    context 'when the version is not found' do
      let(:version) { '5' }

      it { is_expected.to be_nil }
    end
  end

  describe '#valid_user_version?' do
    subject { presenter.valid_user_version? }

    context 'when the user version is valid' do
      let(:user_version) { '1' }

      it { is_expected.to be true }
    end

    context 'when the user version is nil' do
      let(:user_version) { nil }

      it { is_expected.to be true }
    end

    context 'when the user version is invalid' do
      let(:user_version) { '3' }

      it { is_expected.to be false }
    end
  end

  describe '#user_version_withdrawable?' do
    subject { presenter.user_version_withdrawable? }

    context 'when the user version is withdrawable' do
      let(:user_version) { '1' }

      it { is_expected.to be false }
    end

    context 'when the user version is not withdrawable' do
      let(:user_version) { '2' }

      it { is_expected.to be true }
    end
  end

  describe '#user_version_restorable?' do
    subject { presenter.user_version_restorable? }

    context 'when the user version is restorable' do
      let(:user_version) { '2' }

      it { is_expected.to be false }
    end

    context 'when the user version is not restorable' do
      let(:user_version) { '1' }

      it { is_expected.to be true }
    end
  end

  describe '#head_user_version' do
    subject { presenter.head_user_version }

    it { is_expected.to eq '2' }
  end
end
