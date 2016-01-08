require 'spec_helper'

RSpec.describe 'items/_rights.html.erb' do
  let(:object) { double('object', pid: 'druid:abc123') }
  it 'renders the partial content' do
    assign(:object, object)
    render
    expect(rendered)
      .to have_css '.form-group select.form-control option', text: 'world'
    expect(rendered)
      .to have_css '.form-group select.form-control option', text: 'dark'
    expect(rendered)
      .to have_css '.form-group select.form-control option', text: 'stanford'
    expect(rendered)
      .to have_css '.form-group select.form-control option', text: 'none'
    expect(rendered).to have_css 'button.btn.btn-primary', text: 'Update'
  end
end
