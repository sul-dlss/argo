require 'spec_helper'

RSpec.describe 'items/embargo_form.js.erb' do
  it 'renders the JS template' do
    stub_template 'items/_embargo_form.html.erb' => 'stubbed_embargo_form'
    render
    expect(rendered).to have_css '.modal-header h3.modal-title', text: 'Update embargo'
    expect(rendered).to have_css '.modal-body', text: 'stubbed_embargo_form'
    expect(rendered).to have_css '.modal-body button', text: 'Cancel'
  end
end
