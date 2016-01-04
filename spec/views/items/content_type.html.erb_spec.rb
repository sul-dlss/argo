require 'spec_helper'

RSpec.describe 'items/content_type.html.erb' do
  it 'renders the HTML template' do
    stub_template 'items/_content_type.html.erb' => 'stubbed_content_type'
    render
    expect(rendered).to have_css '.container h1', text: 'Set content type'
    expect(rendered).to have_css '.container', text: 'stubbed_content_type'
  end
end
