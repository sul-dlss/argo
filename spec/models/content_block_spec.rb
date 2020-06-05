# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContentBlock, type: :model do
  describe '.active' do
    subject { described_class.active }

    let!(:active1) do
      create(:content_block, start_at: 1.day.ago, end_at: 2.days.from_now)
    end

    let!(:active2) do
      create(:content_block, start_at: 2.days.ago, end_at: 3.days.from_now)
    end

    before do
      # Past
      create(:content_block, start_at: 3.days.ago, end_at: 2.days.ago)
      # Future
      create(:content_block, start_at: 3.days.from_now, end_at: 6.days.from_now)
    end

    it { is_expected.to eq [active1, active2] }
  end

  describe '.primary' do
    subject { described_class.primary }

    let!(:primary1) do
      create(:content_block, ordinal: 1)
    end

    let!(:primary2) do
      create(:content_block, ordinal: 1)
    end

    before do
      # A secondary block
      create(:content_block, ordinal: 2)
    end

    it { is_expected.to eq [primary1, primary2] }
  end

  describe '.secondary' do
    subject { described_class.secondary }

    let!(:secondary1) do
      create(:content_block, ordinal: 2)
    end

    let!(:secondary2) do
      create(:content_block, ordinal: 2)
    end

    before do
      # A primary block
      create(:content_block, ordinal: 1)
    end

    it { is_expected.to eq [secondary1, secondary2] }
  end
end
