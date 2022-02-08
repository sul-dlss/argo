# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::Collection::OverviewComponent, type: :component do
  let(:component) { described_class.new(presenter: presenter) }
  let(:presenter) { instance_double(ArgoShowPresenter, document: doc, cocina: cocina, change_set: change_set, state_service: state_service) }
  let(:change_set) { CollectionChangeSet.new(cocina) }
  let(:cocina) do
    Cocina::Models::Collection.new(externalIdentifier: 'druid:bc234fg5678',
                                   type: Cocina::Models::Vocab.collection,
                                   label: '',
                                   version: 1,
                                   access: {},
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
  let(:edit_rights_button) { rendered.css("a[aria-label='Set rights']") }

  context 'with a Collection' do
    let(:doc) do
      SolrDocument.new('id' => 'druid:kv840xx0000',
                       SolrDocument::FIELD_OBJECT_TYPE => 'collection')
    end

    it 'creates a edit buttons' do
      expect(edit_governing_apo_button).to be_present
      expect(edit_rights_button).to be_present
      expect(edit_copyright_button).to be_present
      expect(edit_license_button).to be_present
      expect(edit_use_statement_button).to be_present
    end
  end
end
