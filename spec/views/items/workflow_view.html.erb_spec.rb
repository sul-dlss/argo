require 'spec_helper'

describe 'items/workflow_view.html.erb' do
  it 'renders the JS template' do
    stub_template 'items/_workflow_view.html.erb' => 'stubbed_workflow_view'
    render
    expect(rendered)
      .to have_css '.modal-header h3.modal-title', text: 'Workflow view'
    expect(rendered).to have_css '.modal-body', text: 'stubbed_workflow_view'
  end
end
