# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OverviewComponent, type: :component do
  let(:component) { described_class.new(solr_document: doc) }
  let(:rendered) { render_inline(component) }
  let(:allows_modification) { true }
  let(:state_service) { instance_double(StateService, allows_modification?: allows_modification) }
  let(:edit_collection_button) { rendered.css("a[aria-label='Edit collections']") }
  let(:edit_copyright_button) { rendered.css("a[aria-label='Edit copyright']") }
  let(:edit_license_button) { rendered.css("a[aria-label='Edit license']") }
  let(:edit_use_statement_button) { rendered.css("a[aria-label='Edit use and reproduction']") }

  before do
    allow(StateService).to receive(:new).and_return(state_service)
  end

  context 'with a DRO' do
    let(:doc) do
      SolrDocument.new('id' => 'druid:kv840xx0000',
                       SolrDocument::FIELD_OBJECT_TYPE => 'item')
    end

    context 'without a license set' do
      it 'shows empty field defaults' do
        expect(rendered.to_html).to include 'Not entered'
        expect(rendered.to_html).to include 'No license'
      end
    end

    context 'with a license set' do
      let(:doc) do
        SolrDocument.new('id' => 'druid:kv840xx0000',
                         SolrDocument::FIELD_OBJECT_TYPE => 'item',
                         'use_license_machine_ssi' => 'CC-BY-NC-SA-4.0')
      end

      it 'shows the full license text' do
        expect(rendered.to_html).to include 'Attribution-NonCommercial Share Alike 4.0 International'
      end
    end

    context 'when allows_modification is true' do
      it 'creates a edit buttons' do
        expect(rendered.css("a[aria-label='Set governing APO']")).to be_present
        expect(rendered.css("a[aria-label='Set rights']")).to be_present

        expect(edit_collection_button).to be_present
        expect(edit_copyright_button).to be_present
        expect(edit_license_button).to be_present
        expect(edit_use_statement_button).to be_present
      end
    end

    context 'when allows_modification is false' do
      let(:allows_modification) { false }

      it 'creates some edit buttons' do
        expect(rendered.css("a[aria-label='Set governing APO']")).to be_present
        expect(rendered.css("a[aria-label='Set rights']")).to be_present

        expect(edit_collection_button).to be_present
        expect(edit_copyright_button).not_to be_present
        expect(edit_license_button).not_to be_present
        expect(edit_use_statement_button).not_to be_present
      end
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
      expect(edit_collection_button).not_to be_present
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
      expect(edit_collection_button).not_to be_present
    end
  end
end
