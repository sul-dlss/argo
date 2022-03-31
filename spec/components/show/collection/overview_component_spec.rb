# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::Collection::OverviewComponent, type: :component do
  let(:component) { described_class.new(presenter: presenter) }
  let(:presenter) { instance_double(ArgoShowPresenter, document: doc, cocina: cocina, change_set: change_set, state_service: state_service) }
  let(:change_set) { CollectionChangeSet.new(cocina) }
  let(:cocina) do
    Cocina::Models::Collection.new(externalIdentifier: 'druid:bc234fg5678',
                                   type: Cocina::Models::ObjectType.collection,
                                   label: 'my collection',
                                   version: 1,
                                   description: {
                                     title: [{ value: 'my collection' }],
                                     purl: 'https://purl.stanford.edu/bc234fg5678'
                                   },
                                   access: {
                                     view: 'world',
                                     copyright: 'This collection is in the Public Domain.',
                                     useAndReproductionStatement: 'Must be used underwater',
                                     license: 'https://creativecommons.org/licenses/by-nc-sa/3.0/legalcode'
                                   },
                                   identification: { sourceId: 'sul:1234' },
                                   administrative: {
                                     hasAdminPolicy: 'druid:hv992ry2431'
                                   })
  end
  let(:rendered) { render_inline(component) }
  let(:allows_modification) { true }
  let(:state_service) { instance_double(StateService, allows_modification?: allows_modification) }

  let(:edit_copyright_button) { rendered.css("a[aria-label='Edit copyright']") }
  let(:edit_license_button) { rendered.css("a[aria-label='Edit license']") }
  let(:edit_use_statement_button) { rendered.css("a[aria-label='Edit use and reproduction']") }
  let(:edit_governing_apo_button) { rendered.css("a[aria-label='Set governing APO']") }
  let(:edit_rights_button) { rendered.css("a[aria-label='Edit rights']") }

  context 'with a Collection' do
    let(:doc) do
      SolrDocument.new('id' => 'druid:kv840xx0000',
                       SolrDocument::FIELD_ACCESS_RIGHTS => 'world',
                       SolrDocument::FIELD_OBJECT_TYPE => 'collection')
    end

    it 'creates a edit buttons' do
      expect(edit_governing_apo_button).to be_present
      expect(edit_rights_button).to be_present
      expect(edit_copyright_button).to be_present
      expect(edit_license_button).to be_present
      expect(edit_use_statement_button).to be_present
    end

    it 'shows the values' do
      expect(rendered.to_html).to include 'World'
      expect(rendered.to_html).to include 'This collection is in the Public Domain.'
      expect(rendered.to_html).to include 'Must be used underwater'
      expect(rendered.to_html).to include 'Attribution Non-Commercial Share Alike 3.0 Unported'
    end
  end
end
