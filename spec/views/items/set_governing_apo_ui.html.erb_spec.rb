require 'spec_helper'

RSpec.describe 'items/set_governing_apo_ui.html.erb' do
  it 'renders the HTML template' do
    stub_template 'items/_set_governing_apo_ui.html.erb' => 'stubbed_set_governing_apo_ui'
    render
    expect(rendered).to have_css '.container h1', text: 'Set governing APO'
    expect(rendered).to have_css '.container', text: 'stubbed_set_governing_apo_ui'
  end
end
