require 'spec_helper'

RSpec.describe 'items/close_version_ui.html.erb' do
  it 'renders the HTML template' do
    stub_template 'items/_close_version_ui.html.erb' => 'stubbed_closed_version'
    render
    expect(rendered).to have_css '.container h1', text: 'Close version'
    expect(rendered).to have_css '.container', text: 'stubbed_closed_version'
  end
end
