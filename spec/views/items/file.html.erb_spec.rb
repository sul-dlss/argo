require 'spec_helper'

RSpec.describe 'items/file.html.erb' do
  it 'renders the HTML template' do
    stub_template 'items/_file.html.erb' => 'stubbed_file'
    render
    expect(rendered).to have_css '.container h1', text: 'Files'
    expect(rendered).to have_css '.container', text: 'stubbed_file'
  end
end
