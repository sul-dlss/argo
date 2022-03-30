# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TechmdComponent, type: :component do
  include Dry::Monads[:result]

  subject(:component) { described_class.new(view_token: 'skret-t0k3n') }

  let(:rendered) { render_inline(component) }

  it 'renders a turbo frame' do
    expect(rendered.css('turbo-frame').first['src']).to eq '/items/skret-t0k3n/technical'
  end
end
