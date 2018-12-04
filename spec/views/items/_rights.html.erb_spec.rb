# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'items/_rights.html.erb' do
  let(:object) { double('object', pid: 'druid:abc123') }
  it 'renders the partial content' do
    assign(:object, object)
    render
    expect(rendered)
      .to have_css '.form-group select.form-control option', text: 'World'
    expect(rendered)
      .to have_css '.form-group select.form-control option', text: 'Dark (Preserve Only)'
    expect(rendered)
      .to have_css '.form-group select.form-control option', text: 'Stanford'
    expect(rendered)
      .to have_css '.form-group select.form-control option', text: 'Citation Only'
    expect(rendered).to have_css 'button.btn.btn-primary', text: 'Update'
  end
end
