# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ItemChangeSet do
  let(:instance) { described_class.new(cocina_item) }
  let(:druid) { 'druid:bc123df4567' }
  let(:cocina_item) { build(:dro, id: druid) }

  describe 'loading from cocina' do
    let(:cocina_item) do
      build(:dro).new(access: {
                        'view' => 'world',
                        'download' => 'stanford'
                      })
    end

    describe '#view_access' do
      subject { instance.view_access }

      it { is_expected.to eq 'world' }
    end

    describe '#download_access' do
      subject { instance.download_access }

      it { is_expected.to eq 'stanford' }
    end
  end
end
