# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'items/add_workflow.html.erb' do
  it 'renders the JS template' do
    stub_template 'items/_add_workflow.html.erb' => 'stubbed_add_workflow'
    controller.request.path_parameters[:id] = 'test'
    render
    expect(rendered)
      .to have_css '.modal-header h3.modal-title', text: 'Add workflow'
    expect(rendered).to have_css '.modal-body', text: 'stubbed_add_workflow'
  end
end
