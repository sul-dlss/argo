require 'spec_helper'

RSpec.describe 'items/source_id_ui.html.erb' do
  it 'renders the HTML template' do
    stub_template 'items/_source_id_ui.html.erb' => 'stubbed_source_id_ui'
    render
    expect(rendered).to have_css '.container h1', text: 'Change source id'
    expect(rendered).to have_css '.container', text: 'source_id_ui'
  end
end
