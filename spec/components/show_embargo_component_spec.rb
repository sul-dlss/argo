# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ShowEmbargoComponent, type: :component do
  let(:component) do
    described_class.new(solr_document: document)
  end

  let(:rendered) { render_inline(component) }

  context 'embargoed with release date' do
    let(:document) do
      SolrDocument.new(
        id: 'druid:kv840xx0000',
        SolrDocument::FIELD_EMBARGO_STATUS => ['embargoed'],
        SolrDocument::FIELD_EMBARGO_RELEASE_DATE => ['24/02/2259']
      )
    end

    it 'displays release date' do
      expect(rendered.to_html).to include 'Embargoed until February 24, 2259'
      link = rendered.css("a[href='/items/druid:kv840xx0000/embargo/edit']")
      expect(link.attr('aria-label').value).to eq 'Manage embargo'
    end
  end

  context 'embargoed without release date' do
    let(:document) do
      SolrDocument.new(
        id: 1,
        SolrDocument::FIELD_EMBARGO_STATUS => ['embargoed']
      )
    end

    it 'does not render anything' do
      expect(rendered.to_html).to eq ''
    end
  end

  context 'not embargoed with release date' do
    let(:document) do
      SolrDocument.new(
        id: 1,
        SolrDocument::FIELD_EMBARGO_STATUS => ['strange occurrence'],
        SolrDocument::FIELD_EMBARGO_RELEASE_DATE => ['24/02/2259']
      )
    end

    it 'does not render anything' do
      expect(rendered.to_html).to eq ''
    end
  end
end
