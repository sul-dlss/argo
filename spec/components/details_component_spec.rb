# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DetailsComponent, type: :component do
  let(:component) { described_class.new(solr_document: doc) }
  let(:rendered) { render_inline(component) }

  context 'with a DRO' do
    let(:doc) do
      SolrDocument.new('id' => 'druid:kv840xx0000',
                       SolrDocument::FIELD_OBJECT_TYPE => 'item')
    end

    it 'creates a edit buttons' do
      expect(rendered.css("a[aria-label='Change source id']")).to be_present
    end
  end

  context 'with an AdminPolicy' do
    let(:doc) do
      SolrDocument.new('id' => 'druid:kv840xx0000',
                       SolrDocument::FIELD_OBJECT_TYPE => 'adminPolicy')
    end

    it 'renders the appropriate buttons' do
      expect(rendered.css("a[aria-label='Change source id']")).not_to be_present
    end
  end
end
