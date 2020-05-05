# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'items/embargo_form.html.erb' do
  it 'renders the JS template' do
    stub_template 'items/_embargo_form.html.erb' => 'stubbed_embargo_form'
    render
    expect(rendered).to have_css '.modal-header h3.modal-title', text: 'Update embargo'
    expect(rendered).to have_css '.modal-body', text: 'stubbed_embargo_form'
    expect(rendered).to have_css '.modal-footer button', text: 'Cancel'
  end
end
