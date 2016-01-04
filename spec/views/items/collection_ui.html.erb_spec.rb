require 'spec_helper'

RSpec.describe 'items/collection_ui.html.erb' do
  it 'renders the HTML template' do
    stub_template 'items/_collection_ui.html.erb' => 'stubbed_collection_ui'
    render
    expect(rendered).to have_css '.container h1', text: 'Edit collections'
    expect(rendered).to have_css '.container', text: 'stubbed_collection_ui'
  end
end
