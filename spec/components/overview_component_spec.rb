# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OverviewComponent, type: :component do
  let(:component) { described_class.new(solr_document: doc) }
  let(:rendered) { render_inline(component) }
  let(:state_service) { instance_double(StateService, allows_modification?: true) }

  before do
    allow(StateService).to receive(:new).and_return(state_service)
  end

  context 'with a DRO' do
    let(:doc) do
      SolrDocument.new('id' => 'druid:kv840xx0000',
                       SolrDocument::FIELD_OBJECT_TYPE => 'item')
    end

    it 'creates a edit buttons' do
      expect(rendered.css("a[aria-label='Set governing APO']")).to be_present
      expect(rendered.css("a[aria-label='Set rights']")).to be_present
      expect(rendered.css("a[aria-label='Edit collections']")).to be_present

      expect(rendered.to_html).to include 'Not entered'
      expect(rendered.to_html).to include 'No license'
    end
  end

  context 'with a Collection' do
    let(:doc) do
      SolrDocument.new('id' => 'druid:kv840xx0000',
                       SolrDocument::FIELD_OBJECT_TYPE => 'collection')
    end

    it 'creates a edit buttons' do
      expect(rendered.css("a[aria-label='Set governing APO']")).to be_present
      expect(rendered.css("a[aria-label='Set rights']")).to be_present
      expect(rendered.css("a[aria-label='Edit collections']")).to be_present
    end
  end

  context 'with an AdminPolicy' do
    let(:doc) do
      SolrDocument.new('id' => 'druid:kv840xx0000',
                       SolrDocument::FIELD_OBJECT_TYPE => 'adminPolicy')
    end

    it 'renders the appropriate buttons' do
      expect(rendered.css("a[aria-label='Set governing APO']")).not_to be_present
      expect(rendered.css("a[aria-label='Set rights']")).not_to be_present
      expect(rendered.css("a[aria-label='Edit collections']")).not_to be_present
    end
  end
end
