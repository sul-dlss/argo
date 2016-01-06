require 'spec_helper'

RSpec.describe 'items/embargo_form.html.erb' do
  it 'renders the HTML template' do
    stub_template 'items/_embargo_form.html.erb' => 'stubbed_embargo_form'
    render
    expect(rendered).to have_css '.container h1', text: 'Update embargo'
    expect(rendered).to have_css '.container', text: 'stubbed_embargo_form'
  end
end
