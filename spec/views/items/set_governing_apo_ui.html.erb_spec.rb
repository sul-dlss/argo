# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'items/set_governing_apo_ui.html.erb' do
  it 'renders the JS template' do
    stub_template 'items/_set_governing_apo_ui.html.erb' => 'stubbed_set_governing_apo_ui'
    render
    expect(rendered)
      .to have_css '.modal-header h3.modal-title', text: 'Set governing APO'
    expect(rendered).to have_css '.modal-body', text: 'stubbed_set_governing_apo_ui'
  end
end
