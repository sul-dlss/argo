require 'spec_helper'

RSpec.describe 'items/rights.js.erb' do
  it 'renders the JS template' do
    stub_template 'items/_rights.html.erb' => 'stubbed_rights'
    render
    expect(rendered)
      .to have_css '.modal-header h3.modal-title', text: 'Set rights'
    expect(rendered).to have_css '.modal-body', text: 'stubbed_rights'
  end
end
