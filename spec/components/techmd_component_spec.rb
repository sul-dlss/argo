# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TechmdComponent, type: :component do
  subject(:component) { described_class.new(view_token: 'skret-t0k3n', presenter:) }

  let(:rendered) { render_inline(component) }
  let(:presenter) { instance_double(ArgoShowPresenter, user_version_view?: user_version_view) }

  context 'when head cocina' do
    let(:user_version_view) { false }

    it 'renders a turbo frame' do
      expect(rendered.css('turbo-frame').first['src']).to eq '/items/skret-t0k3n/technical'
    end
  end

  context 'when user version view' do
    let(:user_version_view) { true }

    it 'does not render' do
      expect(rendered.text).to be_empty
    end
  end
end
