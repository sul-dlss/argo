# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StructuralPresenter do
  subject(:presenter) { described_class.new(structural) }

  let(:structural) { Cocina::Models::DROStructural.new(contains: contains, hasMemberOrders: member_orders) }
  let(:contains) do
    [
      Cocina::Models::FileSet.new(
        type: Cocina::Models::FileSetType.file,
        externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/bb573tm8486-bc91c072-3b0f-4338-a9b2-0f85e1b98e00',
        version: 1,
        label: 'Image 1'
      ),
      Cocina::Models::FileSet.new(
        type: Cocina::Models::FileSetType.file,
        externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/bb573tm8486-bc91c072-3b0f-4338-a9b2-0f85e1b98e11',
        version: 2,
        label: 'Image 2'
      )
    ]
  end
  let(:member_orders) { [] }

  describe '#label' do
    context 'when a virtual object' do
      let(:member_orders) do
        [
          { members: %w[druid:aa111bb2222 druid:cc333dd4444] }
        ]
      end

      it 'returns Constituent' do
        expect(presenter.label).to eq 'Constituent'
      end
    end

    context 'when not a virtual object' do
      it 'returns Resource' do
        expect(presenter.label).to eq 'Resource'
      end
    end
  end

  describe '#number_of_content_items' do
    context 'when a virtual object' do
      let(:member_orders) do
        [
          { members: %w[druid:aa111bb2222 druid:cc333dd4444] }
        ]
      end

      it 'returns the number of constituents' do
        expect(presenter.number_of_content_items).to eq 2
      end
    end

    context 'when not a virtual object' do
      it 'returns the number of contains' do
        expect(presenter.number_of_content_items).to eq 2
      end

      context 'when contains is nil' do
        let(:contains) { [] }

        it 'returns 0' do
          expect(presenter.number_of_content_items).to eq 0
        end
      end
    end
  end

  describe '#enable_csv?' do
    context 'when a virtual object' do
      let(:member_orders) do
        [
          { members: %w[druid:aa111bb2222 druid:cc333dd4444] }
        ]
      end

      it 'returns false' do
        expect(presenter.enable_csv?).to be false
      end
    end

    context 'when not a virtual object' do
      it 'returns true' do
        expect(presenter.enable_csv?).to be true
      end
    end
  end

  describe '#virtual_object?' do
    context 'when a virtual object' do
      let(:member_orders) do
        [
          { members: %w[druid:aa111bb2222 druid:cc333dd4444] }
        ]
      end

      it 'returns true' do
        expect(presenter.virtual_object?).to be true
      end
    end

    context 'when not a virtual object' do
      it 'returns false' do
        expect(presenter.virtual_object?).to be false
      end
    end
  end

  describe '#constituents' do
    context 'when a virtual object' do
      let(:member_orders) do
        [
          { members: %w[druid:aa111bb2222 druid:cc333dd4444] }
        ]
      end

      it 'returns the member orders' do
        expect(presenter.constituents).to eq ['druid:aa111bb2222', 'druid:cc333dd4444']
      end
    end

    context 'when not a virtual object' do
      it 'returns an empty array' do
        expect(presenter.constituents).to be_nil
      end
    end
  end
end
