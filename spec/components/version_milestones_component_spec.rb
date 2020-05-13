# frozen_string_literal: true

require 'rails_helper'

RSpec.describe VersionMilestonesComponent, type: :component do
  subject(:instance) do
    described_class.new(version: 2,
                        title: '2 (2.0.0) Add collection, set rights to citations',
                        steps: steps)
  end

  context 'when the accessioned milestone has display' do
    let(:steps) do
      { 'accessioned' => { display: 'foo',
                           time: DateTime.parse('2020-05-12') } }
    end

    it 'renders something useful' do
      render_inline(instance)
      expect(page).to have_text '2 (2.0.0) Add collection, set rights to citations'
      expect(page).to have_css '.last_step2', visible: false
      expect(page).to have_css 'tr.version2', count: 2
    end
  end

  context "when the accessioned milestone doesn't have display" do
    let(:steps) do
      { 'accessioned' => {} }
    end

    it 'renders something useful' do
      render_inline(instance)
      expect(page).to have_text '2 (2.0.0) Add collection, set rights to citations'
      expect(page).to have_css '.last_step2', visible: false
      expect(page).to have_css 'tr.version2', count: 2
    end
  end
end
