require 'spec_helper'

RSpec.describe 'items/open_version_ui.html.erb' do
  it 'renders the HTML template' do
    stub_template 'items/_open_version_ui.html.erb' => 'stubbed_open_version_ui'
    render
    expect(rendered).to have_css '.container h1', text: 'Open for modification'
    expect(rendered).to have_css '.container', text: 'stubbed_open_version_ui'
  end
end
