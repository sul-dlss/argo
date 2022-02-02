# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DetailsComponent, type: :component do
  let(:component) { described_class.new(presenter: presenter) }
  let(:presenter) { instance_double(ArgoShowPresenter, document: doc, change_set: change_set, cocina: cocina) }
  let(:cocina) { instance_double(Cocina::Models::DRO) }

  let(:change_set) { instance_double(ItemChangeSet, barcode: nil, id: doc.id) }
  let(:rendered) { render_inline(component) }
  let(:doc) do
    SolrDocument.new('id' => 'druid:kv840xx0000',
                     SolrDocument::FIELD_REGISTERED_DATE => ['2012-04-05T01:00:04.148Z'],
                     SolrDocument::FIELD_OBJECT_TYPE => object_type)
  end
  let(:content_type_button) { rendered.css("a[aria-label='Set content type']") }

  context 'with a DRO' do
    let(:object_type) { 'item' }

    it 'creates a edit buttons' do
      expect(rendered.css("a[aria-label='Change source id']")).to be_present
      expect(rendered.to_html).to include 'Not released'
      expect(rendered.to_html).to include 'Not recorded'
      expect(rendered.to_html).to include 'None assigned'
      expect(rendered.css("a[aria-label='Edit tags']")).to be_present
      expect(rendered.css("a[aria-label='Manage catkey']")).to be_present
      expect(content_type_button).to be_present
      expect(rendered.to_html).to include 'Preservation size'
      expect(rendered.to_html).to include 'Content type'
    end
  end

  context 'with a Collection' do
    let(:object_type) { 'collection' }

    it 'creates a edit buttons' do
      expect(rendered.css("a[aria-label='Change source id']")).not_to be_present
      expect(rendered.css("a[aria-label='Edit tags']")).to be_present
      expect(rendered.css("a[aria-label='Manage catkey']")).to be_present
      expect(content_type_button).not_to be_present
      expect(rendered.to_html).not_to include 'Preservation size'
      expect(rendered.to_html).not_to include 'Content type'
    end
  end

  context 'with an AdminPolicy' do
    let(:object_type) { 'adminPolicy' }

    it 'renders the appropriate buttons' do
      expect(rendered.css("a[aria-label='Change source id']")).not_to be_present
      expect(rendered.css("a[aria-label='Edit tags']")).to be_present
      expect(rendered.css("a[aria-label='Manage catkey']")).not_to be_present
      expect(content_type_button).not_to be_present
      expect(rendered.to_html).not_to include 'Content type'
    end
  end
end
