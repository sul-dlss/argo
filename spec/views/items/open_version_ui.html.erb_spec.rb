require 'spec_helper'

RSpec.describe 'items/open_version_ui.html.erb' do
  it 'renders the JS template' do
    stub_template 'items/_open_version_ui.html.erb' => 'stubbed_open_version_ui'
    render
    expect(rendered)
      .to have_css '.modal-header h3.modal-title', text: 'Open for modification'
    expect(rendered).to have_css '.modal-body', text: 'stubbed_open_version_ui'
  end
end
