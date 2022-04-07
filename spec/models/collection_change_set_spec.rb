# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CollectionChangeSet do
  let(:instance) { described_class.new(collection) }
  let(:druid) { 'druid:bc123df4567' }

  describe 'loading from cocina' do
    let(:collection) do
      build(:collection, copyright: 'This collection is in the Public Domain.',
                         use_statement: 'Must be used underwater',
                         license: 'https://creativecommons.org/licenses/by-nc-sa/3.0/legalcode')
    end

    describe '#copyright' do
      subject { instance.copyright }

      it { is_expected.to eq 'This collection is in the Public Domain.' }
    end

    describe '#use_statement' do
      subject { instance.use_statement }

      it { is_expected.to eq 'Must be used underwater' }
    end

    describe '#license' do
      subject { instance.license }

      it { is_expected.to eq 'https://creativecommons.org/licenses/by-nc-sa/3.0/legalcode' }
    end
  end
end
