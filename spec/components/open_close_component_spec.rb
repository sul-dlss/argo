# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OpenCloseComponent, type: :component do
  let(:component) do
    described_class.new(solr_document: doc)
  end

  let(:rendered) { render_inline(component) }
  let(:item_id) { 'druid:kv840xx0000' }
  let(:doc) { SolrDocument.new('id' => item_id) }

  it 'draws the open and close button' do
    expect(rendered.css("a[href='/items/druid:kv840xx0000/versions/close_ui'][data-controller='open-close']").attribute('title').value).to eq 'Close Version'
    expect(rendered.css("a[href='/items/druid:kv840xx0000/versions/open_ui'][data-controller='open-close']").attribute('title').value).to eq 'Open for modification'
  end
end
