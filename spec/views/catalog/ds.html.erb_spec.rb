require 'spec_helper'

RSpec.describe 'catalog/ds.html.erb' do
  it 'renders the HTML template' do
    stub_template 'catalog/_ds.html.erb' => 'stubbed_ds'
    render
    expect(rendered).to have_css '.container', text: 'stubbed_ds'
  end
end
