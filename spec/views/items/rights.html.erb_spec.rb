require 'spec_helper'

RSpec.describe 'items/rights.html.erb' do
  it 'renders the HTML template' do
    stub_template 'items/_rights.html.erb' => 'stubbed_rights'
    render
    expect(rendered).to have_css '.container h1', text: 'Set rights'
    expect(rendered).to have_css '.container', text: 'stubbed_rights'
  end
end
