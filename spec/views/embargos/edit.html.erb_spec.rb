# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'embargos/edit' do
  it 'renders the template' do
    stub_template 'embargos/_form.html.erb' => 'stubbed_embargo_form'
    render
    expect(rendered).to have_css '.modal-header h3.modal-title', text: 'Update embargo'
    expect(rendered).to have_css '.modal-body', text: 'stubbed_embargo_form'
    expect(rendered).to have_css '.modal-footer button', text: 'Cancel'
  end
end
