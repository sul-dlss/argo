require 'spec_helper'

RSpec.describe 'items/tags_ui.html.erb' do
  it 'renders the HTML template' do
    stub_template 'items/_tags_ui.html.erb' => 'stubbed_tags_ui'
    render
    expect(rendered)
      .to have_css '.container h1', text: 'Update tags or delete a tag'
    expect(rendered).to have_css '.container', text: 'stubbed_tags_ui'
  end
end
