require 'spec_helper'

RSpec.describe 'items/_add_workflow.html.erb' do
  it 'renders the partial content' do
    controller.request.path_parameters[:id] = 'test'
    render
    expect(rendered).to have_css 'form .form-group select'
    expect(rendered).to have_css 'form button.btn.btn-primary', text: 'Add'
  end
end
