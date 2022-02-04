# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::DetailsComponent, type: :component do
  let(:component) { described_class.new(presenter: presenter) }
  let(:presenter) { instance_double(ArgoShowPresenter, document: doc, change_set: change_set, cocina: cocina, state_service: state_service) }
  let(:cocina) { instance_double(Cocina::Models::DRO) }

  let(:change_set) { instance_double(ItemChangeSet, barcode: nil, id: doc.id) }
  let(:rendered) { render_inline(component) }
  let(:allows_modification) { true }
  let(:state_service) { instance_double(StateService, allows_modification?: allows_modification) }
  let(:doc) do
    SolrDocument.new('id' => 'druid:kv840xx0000',
                     SolrDocument::FIELD_REGISTERED_DATE => ['2012-04-05T01:00:04.148Z'],
                     SolrDocument::FIELD_OBJECT_TYPE => object_type)
  end
  let(:content_type_button) { rendered.css("a[aria-label='Set content type']") }
  let(:source_id_button) { rendered.css("a[aria-label='Change source id']") }
  let(:catkey_button) { rendered.css("a[aria-label='Manage catkey']") }
  let(:barcode_button) { rendered.css("a[aria-label='Edit barcode']") }

  context 'with a DRO' do
    let(:object_type) { 'item' }

    context 'when allows_modification is true' do
      it 'creates a edit buttons' do
        expect(source_id_button).to be_present
        expect(rendered.to_html).to include 'Not released'
        expect(rendered.to_html).to include 'Not recorded'
        expect(rendered.to_html).to include 'None assigned'
        expect(catkey_button).to be_present
        expect(content_type_button).to be_present
        expect(barcode_button).to be_present
        expect(rendered.to_html).to include 'Preservation size'
        expect(rendered.to_html).to include 'Content type'
        expect(rendered.css("a[aria-label='Edit tags']")).to be_present
      end
    end

    context 'when allows_modification is false' do
      let(:allows_modification) { false }

      it 'creates only the tag edit buttons' do
        expect(source_id_button).not_to be_present
        expect(catkey_button).not_to be_present
        expect(content_type_button).not_to be_present
        expect(barcode_button).not_to be_present
        expect(rendered.css("a[aria-label='Edit tags']")).to be_present
      end
    end
  end

  context 'with a Collection' do
    let(:object_type) { 'collection' }

    context 'when allows_modification is true' do
      it 'creates a edit buttons' do
        expect(source_id_button).not_to be_present
        expect(rendered.css("a[aria-label='Edit tags']")).to be_present
        expect(catkey_button).to be_present
        expect(content_type_button).not_to be_present
        expect(rendered.to_html).not_to include 'Preservation size'
        expect(rendered.to_html).not_to include 'Content type'
      end
    end
  end

  context 'with an AdminPolicy' do
    let(:object_type) { 'adminPolicy' }

    context 'when allows_modification is true' do
      it 'renders the appropriate buttons' do
        expect(source_id_button).not_to be_present
        expect(rendered.css("a[aria-label='Edit tags']")).to be_present
        expect(catkey_button).not_to be_present
        expect(content_type_button).not_to be_present
        expect(rendered.to_html).not_to include 'Content type'
      end
    end
  end
end
