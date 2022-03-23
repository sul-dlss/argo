# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ItemChangeSet do
  let(:instance) { described_class.new(item) }
  let(:druid) { 'druid:bc123df4567' }
  let(:item) { build(:item, id: druid) }

  context 'when bad embargo_access' do
    subject { instance.validate(embargo_access: 'stanford-nobody') }

    it { is_expected.to be false }
  end

  describe 'loading from cocina' do
    before do
      item.embargo = build(:embargo)
    end

    describe '#embargo_release_date' do
      subject { instance.embargo_release_date }

      it { is_expected.to eq '2040-05-05' }
    end

    describe '#embargo_access' do
      subject { instance.embargo_access }

      it { is_expected.to eq 'stanford' }
    end
  end
end
