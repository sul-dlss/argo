# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'workflows/show' do
  it 'renders the template' do
    stub_template 'workflows/_show.html.erb' => 'stubbed_workflow_view'
    render
    expect(rendered)
      .to have_css '.modal-header h1.modal-title', text: 'Workflow view'
    expect(rendered).to have_css '.modal-body', text: 'stubbed_workflow_view'
  end
end
