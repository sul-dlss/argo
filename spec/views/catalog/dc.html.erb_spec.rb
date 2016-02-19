require 'spec_helper'

RSpec.describe 'catalog/dc.html.erb' do
  it 'renders the HTML template' do
    stub_template 'catalog/_dc.html.erb' => 'stubbed_dc'
    render
    expect(rendered)
      .to have_css '.container h1', text: 'Dublin Core (derived from MODS)'
    expect(rendered).to have_css '.container', text: 'stubbed_dc'
  end
end
