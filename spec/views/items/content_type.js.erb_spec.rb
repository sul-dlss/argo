require 'spec_helper'

RSpec.describe 'items/content_type.js.erb' do
  it 'renders the JS template' do
    stub_template 'items/_content_type.html.erb' => 'stubbed_content_type'
    render
    expect(rendered).to have_css '.modal-header h3.modal-title', text: 'Set content type'
    expect(rendered).to have_css '.modal-body', text: 'stubbed_content_type'
  end
end
