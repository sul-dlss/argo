require 'spec_helper'

RSpec.describe ViewSwitcher do
  let(:view_switcher) { described_class.new(:cool_view, :cool_view_path) }
  describe '#name' do
    it 'returns name' do
      expect(view_switcher.name).to eq :cool_view
    end
  end
  describe '#path' do
    it 'returns view' do
      expect(view_switcher.path).to eq :cool_view_path
    end
  end
end
