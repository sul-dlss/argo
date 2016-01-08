require 'spec_helper'

RSpec.describe 'dor/_reindex.html.erb' do
  it 'renders the partial content' do
    render
    expect(rendered).to have_css 'p', text: 'Status:ok'
    expect(rendered).to have_css 'p', text: 'Solr Document: nil'
  end
end
