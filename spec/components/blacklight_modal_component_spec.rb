# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BlacklightModalComponent, type: :component do
  it 'renders the bootstrap modal' do
    render_inline(described_class.new) do |component|
      component.with(:header, 'header')
      component.with(:body, 'body')
      component.with(:footer, 'footer')
    end
    expect(page).to have_button('×')
    expect(page).to have_content('header')
    expect(page).to have_content('body')
    expect(page).to have_content('footer')
  end
end
