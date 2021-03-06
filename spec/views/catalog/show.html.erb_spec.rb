# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'catalog/show.html.erb' do
  let(:document) { SolrDocument.new id: 'xyz', content_type_ssim: 'a' }
  let(:title) { 'Long title that should be truncated at 50 characters' }
  let(:blacklight_config) { CatalogController.blacklight_config }
  let(:document_presenter) { instance_double(Blacklight::ShowPresenter, html_title: title) }

  before do
    assign :document, document
    allow(view).to receive(:blacklight_config).and_return(blacklight_config)
    allow(view).to receive(:render_link_rel_alternates)
    allow(view).to receive(:render_document_class)
    allow(view).to receive_messages(
      current_search_session: nil,
      search_session: {},
      search_state: Blacklight::SearchState.new({}, blacklight_config)
    )
  end

  it 'assigns page title, truncating it' do
    expect(view).to receive(:document_presenter).and_return(document_presenter)
    expect(view).to receive(:render_document_sidebar_partial)
    expect(view).to receive(:render_document_partials)
    render
    expect(view.instance_variable_get(:@page_title))
      .to eq 'Long title that should be truncated at 50 chara... - Argo'
  end
end
