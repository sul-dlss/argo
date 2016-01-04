require 'spec_helper'

RSpec.describe 'dor/reindex.html.erb' do
  it 'renders the HTML template' do
    stub_template 'dor/_reindex.html.erb' => 'stubbed_reindex'
    render
    expect(rendered).to have_css '.container', text: 'stubbed_reindex'
  end
end
