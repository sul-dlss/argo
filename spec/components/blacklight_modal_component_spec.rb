# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BlacklightModalComponent, type: :component do
  it 'renders the bootstrap modal' do
    render_inline(described_class.new) do |component|
      component.with_header { 'header' }
      component.with_body { 'body' }
      component.with_footer { 'footer' }
    end
    expect(page).to have_css('.btn-close')
    expect(page).to have_content('header')
    expect(page).to have_content('body')
    expect(page).to have_content('footer')
  end
end
