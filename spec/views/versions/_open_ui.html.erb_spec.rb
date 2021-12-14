# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'versions/_open_ui.html.erb' do
  before do
    @cocina_object = instance_double(Cocina::Models::DRO, externalIdentifier: 'druid:abc123')
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
