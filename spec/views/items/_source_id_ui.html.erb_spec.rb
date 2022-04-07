# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'items/_source_id_ui' do
  before do
    @item = build(:item, source_id: 'sul:99999')
  end

  it 'renders the partial content' do
    render
    expect(rendered)
      .to have_css 'form input.form-control[value="sul:99999"]'
    expect(rendered).to have_css 'p.form-text'
    expect(rendered).to have_css 'button.btn.btn-primary', text: 'Update'
  end
end
