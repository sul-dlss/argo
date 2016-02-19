require 'spec_helper'

RSpec.describe 'items/collection_ui.js.erb' do
  it 'renders the JS template' do
    stub_template 'items/_collection_ui.html.erb' => 'stubbed_collection_ui'
    render
    expect(rendered)
      .to have_css '.modal-header h3.modal-title', text: 'Edit collections'
    expect(rendered).to have_css '.modal-body', text: 'stubbed_collection_ui'
  end
end
