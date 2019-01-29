# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'workflows/show.html.erb' do
  it 'renders the JS template' do
    stub_template 'workflows/_show.html.erb' => 'stubbed_workflow_view'
    render
    expect(rendered)
      .to have_css '.modal-header h3.modal-title', text: 'Workflow view'
    expect(rendered).to have_css '.modal-body', text: 'stubbed_workflow_view'
  end
end
