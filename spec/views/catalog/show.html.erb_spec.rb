# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'catalog/show.html.erb' do
  let(:document) { SolrDocument.new id: 'xyz', format: 'a' }
  let(:title) { 'Long title that should be truncated at 50 characters' }
  let(:blacklight_config) { Blacklight::Configuration.new }
  let(:query_params) { { controller: 'catalog', action: 'show' } }
  let(:search_state) { Blacklight::SearchState.new(query_params, blacklight_config) }

  before do
    assign :document, document
    allow(view).to receive(:blacklight_config).and_return(blacklight_config)
    allow(view).to receive(:search_state).and_return search_state
  end

  it 'assigns page title, truncating it' do
    expect(view).to receive(:document_show_html_title).and_return(title)
    expect(view).to receive(:render_document_sidebar_partial)
    expect(view).to receive(:item_page_entry_info)
    expect(view).to receive(:render_document_partial).twice
    expect(view).to receive(:current_search_session)
    expect(view).to receive(:should_render_field?).at_least(:once).and_return false
    render
    expect(view.instance_variable_get(:@page_title))
      .to eq 'Long title that should be truncated at 50 chara... - Argo'
  end
end
