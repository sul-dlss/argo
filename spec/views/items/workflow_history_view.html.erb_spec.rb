require 'spec_helper'

RSpec.describe 'items/workflow_history_view.html.erb' do
  it 'renders the HTML template' do
    stub_template 'items/_workflow_history_view.html.erb' => 'stubbed_wf_history_view'
    render
    expect(rendered).to have_css '.container h1', text: 'Workflow history'
    expect(rendered).to have_css '.container', text: 'stubbed_wf_history_view'
  end
end
