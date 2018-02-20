require 'spec_helper'

RSpec.describe 'catalog/dc.html.erb' do
  it 'renders the JS template' do
    stub_template 'catalog/_dc.html.erb' => 'stubbed_dc'
    render
    expect(rendered)
      .to have_css '.modal-header h3.modal-title', text: 'Dublin Core (derived from MODS)'
    expect(rendered).to have_css '.modal-body', text: 'stubbed_dc'
  end
end
