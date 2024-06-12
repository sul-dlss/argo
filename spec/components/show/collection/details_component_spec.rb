# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::Collection::DetailsComponent, type: :component do
  let(:component) { described_class.new(presenter:) }
  let(:presenter) { instance_double(ArgoShowPresenter, document: doc, change_set:, cocina:, version_service:) }
  let(:cocina) { instance_double(Cocina::Models::Collection) }

  let(:change_set) { instance_double(ItemChangeSet, barcode: nil, id: doc.id, catalog_record_ids: []) }
  let(:rendered) { render_inline(component) }
  let(:version_service) { instance_double(VersionService, open_and_not_processing?: true) }
  let(:doc) do
    SolrDocument.new('id' => 'druid:kv840xx0000',
                     SolrDocument::FIELD_REGISTERED_DATE => ['2012-04-05T01:00:04.148Z'],
                     SolrDocument::FIELD_OBJECT_TYPE => object_type)
  end
  let(:catalog_record_id_button) { rendered.css("a[aria-label='#{CatalogRecordId.manage_label}']") }
  let(:object_type) { 'collection' }

  context 'when open is true' do
    it 'creates a edit buttons' do
      expect(rendered.css("a[aria-label='Edit tags']")).to be_present
      expect(catalog_record_id_button).to be_present
    end
  end
end
