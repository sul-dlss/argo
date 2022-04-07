# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'versions/_open_ui' do
  before do
    @item = build(:item)
  end

  it 'renders the partial content' do
    render
    expect(rendered).to have_css 'label', text: 'Type'
    expect(rendered).to have_css 'select#significance'
    expect(rendered)
      .to have_css 'label', text: 'Version description'
    expect(rendered).to have_css 'textarea#description.form-control'
    expect(rendered).to have_css 'button.btn.btn-primary', text: 'Open Version'
  end
end
