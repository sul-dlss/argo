# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'versions/_close_ui' do
  before do
    @cocina_object = instance_double(Cocina::Models::DRO, externalIdentifier: 'druid:abc123')
    assign(:significance_selected, major: false, minor: true, admin: nil)
  end

  it 'renders the partial content' do
    render
    expect(rendered).to have_css 'form'
    expect(rendered).to have_css 'label', text: 'Type'
    expect(rendered).to have_css 'select option[selected]', text: 'Minor'
    expect(rendered).to have_css 'select option[value="major"]'
    expect(rendered).to have_css 'select option[value="minor"]'
    expect(rendered).to have_css 'select option[value="admin"]'
    expect(rendered)
      .to have_css 'label', text: 'Version description'
    expect(rendered).to have_css 'textarea.form-control'
    expect(rendered).to have_css 'button.btn.btn-primary', text: 'Close Version'
  end
end
