# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'workflows/new.html.erb' do
  it 'renders the JS template' do
    stub_template 'workflows/_new.html.erb' => 'stubbed_add_workflow'
    controller.request.path_parameters[:id] = 'test'
    render
    expect(rendered)
      .to have_css '.modal-header h3.modal-title', text: 'Add workflow'
    expect(rendered).to have_css '.modal-body', text: 'stubbed_add_workflow'
  end
end
