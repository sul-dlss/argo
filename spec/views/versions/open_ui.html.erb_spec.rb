# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'versions/open_ui.html.erb' do
  it 'renders the JS template' do
    stub_template 'versions/_open_ui.html.erb' => 'stubbed_open_version_ui'
    render
    expect(rendered)
      .to have_css '.modal-header h3.modal-title', text: 'Open for modification'
    expect(rendered).to have_css '.modal-body', text: 'stubbed_open_version_ui'
  end
end
