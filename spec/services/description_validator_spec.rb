# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DescriptionValidator do
  describe '#valid?' do
    let(:instance) { described_class.new(csv) }

    context 'with duplicate columns' do
      let(:csv) { CSV.parse('druid,title1:value,title2:value,title1:value,title2:value,title3:value', headers: true) }

      it 'finds errors' do
        expect(instance.valid?).to be false
        expect(instance.errors).to eq [
          'Duplicate column headers: The header title1:value should occur only once.',
          'Duplicate column headers: The header title2:value should occur only once.'
        ]
      end
    end
  end
end
