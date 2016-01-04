require 'spec_helper'

RSpec.describe 'items/add_workflow.html.erb' do
  it 'renders the HTML template' do
    stub_template 'items/_add_workflow.html.erb' => 'stubbed_add_workflow'
    controller.request.path_parameters[:id] = 'test'
    render
    expect(rendered).to have_css '.container h1', text: 'Add workflow'
    expect(rendered).to have_css '.container', text: 'stubbed_add_workflow'
  end
end
