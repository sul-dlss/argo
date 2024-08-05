# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::Item::DetailsComponent, type: :component do
  let(:component) { described_class.new(presenter:) }
  let(:presenter) { instance_double(ArgoShowPresenter, document: doc, change_set:, cocina:, version_service:, version_or_user_version_view?: false) }
  let(:cocina) { instance_double(Cocina::Models::DRO) }

  let(:change_set) { instance_double(ItemChangeSet, barcode: nil, id: doc.id, catalog_record_ids: []) }
  let(:rendered) { render_inline(component) }
  let(:open) { true }
  let(:version_service) { instance_double(VersionService, open_and_not_assembling?: open) }
  let(:doc) do
    SolrDocument.new('id' => 'druid:kv840xx0000',
                     SolrDocument::FIELD_REGISTERED_DATE => ['2012-04-05T01:00:04.148Z'],
                     SolrDocument::FIELD_OBJECT_TYPE => object_type,
                     SolrDocument::FIELD_DOI => '10.25740/yr775yn6440',
                     SolrDocument::FIELD_ORCIDS => %w[0000-0002-7262-6251 0000-0002-7262-999X])
  end
  let(:object_type) { 'item' }

  let(:content_type_button) { rendered.css("a[aria-label='Set content type']") }
  let(:source_id_button) { rendered.css("a[aria-label='Change source id']") }
  let(:catalog_record_id_button) { rendered.css("a[aria-label='#{CatalogRecordId.manage_label}']") }
  let(:barcode_button) { rendered.css("a[aria-label='Edit barcode']") }

  context 'when open is true' do
    it 'creates a edit buttons' do
      expect(source_id_button).to be_present
      expect(rendered.to_html).to include 'Not released'
      expect(rendered.to_html).to include 'Not recorded'
      expect(rendered.to_html).to include 'None assigned'
      expect(catalog_record_id_button).to be_present
      expect(content_type_button).to be_present
      expect(barcode_button).to be_present
      expect(rendered.to_html).to include 'Preservation size'
      expect(rendered.to_html).to include 'Content type'
      expect(rendered.css("a[aria-label='Edit tags']")).to be_present
    end

    it 'includes doi and orcid when available' do
      expect(rendered.to_html).to include '10.25740/yr775yn6440'
      expect(rendered.to_html).to include '0000-0002-7262-6251, 0000-0002-7262-999X'
    end
  end

  context 'when open is false' do
    let(:open) { false }

    it 'creates only the tag edit buttons' do
      expect(source_id_button).not_to be_present
      expect(catalog_record_id_button).not_to be_present
      expect(content_type_button).not_to be_present
      expect(barcode_button).not_to be_present
      expect(rendered.css("a[aria-label='Edit tags']")).to be_present
    end
  end
end
