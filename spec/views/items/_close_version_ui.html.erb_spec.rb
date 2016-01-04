require 'spec_helper'

RSpec.describe 'items/_close_version_ui.html.erb' do
  let(:object) { double('object', pid: 'druid:abc123')}
  it 'renders the partial content' do
    assign(:object, object)
    render
    expect(rendered).to have_css 'form'
    expect(rendered).to have_css '.form-group label', text: 'Type'
    expect(rendered).to have_css '.form-group select.form-control'
    expect(rendered)
      .to have_css '.form-group label', text: 'Version description'
    expect(rendered).to have_css '.form-group textarea.form-control'
    expect(rendered).to have_css 'button.btn.btn-primary', text: 'Close Version'
  end
end
