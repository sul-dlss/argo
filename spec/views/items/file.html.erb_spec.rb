require 'spec_helper'

RSpec.describe 'items/file.html.erb' do
  it 'renders the JS template' do
    stub_template 'items/_file.html.erb' => 'stubbed_file'
    render
    expect(rendered).to have_css '.modal-header h3.modal-title', text: 'Files'
    expect(rendered).to have_css '.modal-body', text: 'stubbed_file'
  end
end
