# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BlacklightModalComponent, type: :component do
  it 'renders the bootstrap modal' do
    render_inline(described_class.new) do |component|
      component.header { 'header' }
      component.body { 'body' }
      component.footer { 'footer' }
    end
    expect(page).to have_button('×')
    expect(page).to have_content('header')
    expect(page).to have_content('body')
    expect(page).to have_content('footer')
  end
end
