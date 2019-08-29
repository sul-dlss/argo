# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'versions/_close_ui.html.erb' do
  let(:object) { double('object', pid: 'druid:abc123') }

  it 'renders the partial content' do
    assign(:object, object)
    assign(:significance_selected, major: false, minor: true, admin: nil)
    render
    expect(rendered).to have_css 'form'
    expect(rendered).to have_css '.form-group label', text: 'Type'
    expect(rendered).to have_css '.form-group select.form-control option[selected]', text: 'Minor'
    expect(rendered).to have_css '.form-group select.form-control option[value="major"]'
    expect(rendered).to have_css '.form-group select.form-control option[value="minor"]'
    expect(rendered).to have_css '.form-group select.form-control option[value="admin"]'
    expect(rendered)
      .to have_css '.form-group label', text: 'Version description'
    expect(rendered).to have_css '.form-group textarea.form-control'
    expect(rendered).to have_css 'button.btn.btn-primary', text: 'Close Version'
  end
end
