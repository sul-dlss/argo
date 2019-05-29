# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'items/tags_ui.html.erb' do
  it 'renders the JS template' do
    stub_template 'items/_tags_ui.html.erb' => 'stubbed_tags_ui'
    render
    expect(rendered)
      .to have_css '.modal-header h3.modal-title', text: 'Update tags or delete a tag'
    expect(rendered).to have_css '.modal-body', text: 'stubbed_tags_ui'
  end
end
