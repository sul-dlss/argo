require 'spec_helper'

describe 'items/workflow_view.html.erb' do
  it 'renders the HTML template' do
    stub_template 'items/_workflow_view.html.erb' => 'stubbed_workflow_view'
    render
    expect(rendered)
      .to have_css '.container h1', text: 'Workflow view'
    expect(rendered).to have_css '.container', text: 'stubbed_workflow_view'
  end
end
