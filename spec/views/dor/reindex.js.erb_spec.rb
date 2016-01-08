require 'spec_helper'

RSpec.describe 'dor/reindex.js.erb' do
  it 'renders the JS template' do
    stub_template 'dor/_reindex.html.erb' => 'stubbed_reindex'
    render
    expect(rendered)
      .to have_css '.modal-header h3.modal-title', text: 'Reindex status'
    expect(rendered).to have_css '.modal-body', text: 'stubbed_reindex'
  end
end
