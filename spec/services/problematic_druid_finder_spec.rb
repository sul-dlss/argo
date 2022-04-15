# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProblematicDruidFinder do
  subject(:finder) { described_class.new(druids:, ability:) }

  let(:ability) { instance_double(Ability, can?: can_manage) }
  let(:can_manage) { true }
  let(:druids) { %w[druid:one123 druid:two234 druid:thr345] }

  describe '.find' do
    before do
      allow(described_class).to receive(:new).and_return(finder)
    end

    it 'creates an instance and calls `#find`' do
      allow(finder).to receive(:find)
      described_class.find(druids:, ability:)
      expect(finder).to have_received(:find).once
    end
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
        allow(Dor::Services::Client).to receive(:object).and_return(object_client)
      end

      let(:object_client) { instance_double(Dor::Services::Client::Object, find: nil) }

      it 'returns an array with two empty arrays' do
        expect(finder.find).to eq([[], []])
      end
    end

    context 'with not found druids' do
      before do
        allow(object_client1).to receive(:find).and_raise(Dor::Services::Client::NotFoundResponse)
        allow(object_client2).to receive(:find).and_raise(Dor::Services::Client::NotFoundResponse)

        allow(Dor::Services::Client).to receive(:object).with('druid:one123').and_return(object_client1)
        allow(Dor::Services::Client).to receive(:object).with('druid:thr345').and_return(object_client2)
        allow(Dor::Services::Client).to receive(:object).with('druid:two234').and_return(object_client3)
      end

      let(:object_client1) { instance_double(Dor::Services::Client::Object) }
      let(:object_client2) { instance_double(Dor::Services::Client::Object) }
      let(:object_client3) { instance_double(Dor::Services::Client::Object, find: cocina_model) }
      let(:cocina_model) { instance_double(Cocina::Models::DRO) }

      it 'returns an array with a non-empty array and an empty array (in that order)' do
        expect(finder.find).to eq([%w[druid:one123 druid:thr345], []])
      end
    end

    context 'with unauthorized druids' do
      let(:can_manage) { false }
      let(:object_client) { instance_double(Dor::Services::Client::Object, find: nil) }

      before do
        allow(Dor::Services::Client).to receive(:object).and_return(object_client)
      end

      it 'returns an array with an empty array and a non-empty array (in that order)' do
        expect(finder.find).to eq([[], %w[druid:one123 druid:two234 druid:thr345]])
      end
    end

    context 'with not found and unauthorized druids' do
      let(:can_manage) { false }
      let(:object_client1) { instance_double(Dor::Services::Client::Object) }
      let(:object_client2) { instance_double(Dor::Services::Client::Object, find: cocina_model) }
      let(:object_client3) { instance_double(Dor::Services::Client::Object, find: cocina_model) }
      let(:cocina_model) { instance_double(Cocina::Models::DRO) }

      before do
        allow(object_client1).to receive(:find).and_raise(Dor::Services::Client::NotFoundResponse)

        allow(Dor::Services::Client).to receive(:object).with('druid:two234').and_return(object_client1)
        allow(Dor::Services::Client).to receive(:object).with('druid:one123').and_return(object_client2)
        allow(Dor::Services::Client).to receive(:object).with('druid:thr345').and_return(object_client3)
      end

      it 'returns an array with two non-empty arrays' do
        expect(finder.find).to eq([%w[druid:two234], %w[druid:one123 druid:thr345]])
      end
    end
  end
end
