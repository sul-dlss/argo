# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProblematicDruidFinder do
  subject(:finder) { described_class.new(druids: druids, ability: ability) }

  let(:ability) { instance_double(Ability, can?: can_manage) }
  let(:can_manage) { true }
  let(:druids) { %w(druid:one123 druid:two234 druid:thr345) }

  describe '.find' do
    before do
      allow(described_class).to receive(:new).and_return(finder)
    end

    # rubocop:disable RSpec/SubjectStub
    it 'creates an instance and calls `#find`' do
      allow(finder).to receive(:find)
      described_class.find(druids: druids, ability: ability)
      expect(finder).to have_received(:find).once
    end
    # rubocop:enable RSpec/SubjectStub
  end

  describe '.new' do
    it 'has a `druids` attribute' do
      expect(finder.druids).to eq(druids)
    end

    it 'has an `ability` attribute' do
      expect(finder.ability).to eq(ability)
    end
  end

  describe '#find' do
    context 'when `druids` is empty' do
      let(:druids) { [] }

      it 'returns an array with two empty arrays' do
        expect(finder.find).to eq([[], []])
      end
    end

    context 'when no druids are problematic' do
      before do
        allow(Dor).to receive(:find)
      end

      it 'returns an array with two empty arrays' do
        expect(finder.find).to eq([[], []])
      end
    end

    context 'with not found druids' do
      before do
        allow(Dor).to receive(:find).with('druid:one123').and_raise(ActiveFedora::ObjectNotFoundError)
        allow(Dor).to receive(:find).with('druid:thr345').and_raise(ActiveFedora::ObjectNotFoundError)
        allow(Dor).to receive(:find).with('druid:two234')
      end

      it 'returns an array with a non-empty array and an empty array (in that order)' do
        expect(finder.find).to eq([%w(druid:one123 druid:thr345), []])
      end
    end

    context 'with unauthorized druids' do
      let(:can_manage) { false }

      before do
        allow(Dor).to receive(:find)
      end

      it 'returns an array with an empty array and a non-empty array (in that order)' do
        expect(finder.find).to eq([[], %w(druid:one123 druid:two234 druid:thr345)])
      end
    end

    context 'with not found and unauthorized druids' do
      let(:can_manage) { false }

      before do
        allow(Dor).to receive(:find).with('druid:two234').and_raise(ActiveFedora::ObjectNotFoundError)
        allow(Dor).to receive(:find).with('druid:one123')
        allow(Dor).to receive(:find).with('druid:thr345')
      end

      it 'returns an array with two non-empty arrays' do
        expect(finder.find).to eq([%w(druid:two234), %w(druid:one123 druid:thr345)])
      end
    end
  end
end
