# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::ControlsComponent, type: :component do
  let(:component) do
    described_class.new(manager:, presenter:)
  end

  let(:url_helpers) { Rails.application.routes.url_helpers }
  let(:governing_apo_id) { 'druid:hv992yv2222' }
  let(:manager) { true }
  let(:rendered) { render_inline(component) }
  let(:presenter) { instance_double(ArgoShowPresenter, document: doc, open?: open, cocina:, openable?: true, open_and_not_assembling?: open) }
  let(:cocina) { instance_double(Cocina::Models::DRO, dro?: dro, type: 'https://cocina.sul.stanford.edu/models/book') }

  before do
    rendered
  end

  context 'when the object is a DRO the user can manage and no catalog record ID or embargo info' do
    let(:item_id) { 'druid:kv840xx0000' }
    let(:dro) { true }
    let(:doc) do
      SolrDocument.new('id' => item_id,
                       'processing_status_text_ssi' => processing_status,
                       SolrDocument::FIELD_OBJECT_TYPE => 'item',
                       CatalogRecordId.index_field => catalog_record_id,
                       SolrDocument::FIELD_APO_ID => [governing_apo_id],
                       SolrDocument::FIELD_LAST_PUBLISHED_DATE => last_published,
                       SolrDocument::FIELD_WORKFLOW_ERRORS => workflow_errors)
    end
    let(:catalog_record_id) { nil }
    let(:last_published) { nil }
    let(:workflow_errors) { nil }
    let(:processing_status) { 'not registered' }

    context 'when the object is unlocked' do
      let(:open) { true }

      it 'draws the buttons' do
        expect(page).to have_link 'Reindex', href: '/dor/reindex/druid:kv840xx0000'
        expect(page).to have_link 'Add workflow', href: '/items/druid:kv840xx0000/workflows/new'
        expect(page).to have_link 'Republish', href: '/items/druid:kv840xx0000/publish'
        expect(rendered.css("a.disabled[data-turbo-confirm][data-turbo-method='delete'][href='/items/druid:kv840xx0000/purge']").inner_text).to eq 'Purge'
        expect(page).to have_link 'Manage release', href: '/items/druid:kv840xx0000/manage_release'
        expect(page).to have_link 'Create embargo', href: '/items/druid:kv840xx0000/embargo/new'
        expect(rendered.css("a[data-turbo-method='post'][href='/items/druid:kv840xx0000/apply_apo_defaults']").inner_text).to eq 'Apply APO defaults'
        expect(page).to have_link 'Download Cocina spreadsheet', href: '/items/druid:kv840xx0000/descriptive.csv'
        expect(page).to have_link 'Upload Cocina spreadsheet', href: '/items/druid:kv840xx0000/descriptive/edit'
        expect(page).to have_link 'Text extraction', href: '/items/druid:kv840xx0000/text_extraction/new'

        expect(rendered.css('a').size).to eq(10)
        expect(rendered.css('a.disabled').size).to eq 2 # purge, republish are disabled
      end

      context "with a user that can't manage the object" do
        let(:manager) { false }

        it 'does not generate errors given an object that has no associated APO' do
          expect(rendered.css('a').to_html).to eq ''
        end
      end

      context 'when the item has a catalog record ID' do
        let(:catalog_record_id) { "#{CatalogRecordId.indexing_prefix}:1234567" }

        it 'includes the descriptive metadata refresh button and the correct count of actions' do
          expect(page).to have_link 'Refresh', href: '/items/druid:kv840xx0000/refresh_metadata'
          expect(page).to have_link 'Manage serials', href: '/items/druid:kv840xx0000/serials/edit'
          expect(page).to have_link 'Text extraction', href: '/items/druid:kv840xx0000/text_extraction/new'

          expect(rendered.css('a').size).to eq(12)
        end
      end

      context 'when the item has previously been published' do
        let(:last_published) { '2021-01-01T00:00:00Z' }

        it 'the republish button is active' do
          expect(page).to have_link 'Republish', href: '/items/druid:kv840xx0000/publish'

          expect(rendered.css('a.disabled').size).to eq 1 # purge is disabled
          expect(page).to have_no_css 'a.disabled', text: 'Republish'
        end
      end
    end

    context 'when the object is locked' do
      let(:open) { false }

      it 'the embargo and apply APO buttons are disabled' do
        expect(page).to have_link 'Reindex', href: '/dor/reindex/druid:kv840xx0000'
        expect(page).to have_link 'Add workflow', href: '/items/druid:kv840xx0000/workflows/new'
        expect(page).to have_link 'Republish', href: '/items/druid:kv840xx0000/publish'
        expect(rendered.css("a.disabled[data-turbo-confirm][data-turbo-method='delete'][href='/items/druid:kv840xx0000/purge']").inner_text).to eq 'Purge'
        expect(page).to have_link 'Manage release', href: '/items/druid:kv840xx0000/manage_release'
        expect(page).to have_link 'Download Cocina spreadsheet', href: '/items/druid:kv840xx0000/descriptive.csv'
        expect(page).to have_no_link 'Upload Cocina spreadsheet', href: '/items/druid:kv840xx0000/descriptive/edit'
        expect(page).to have_link 'Text extraction', href: '/items/druid:kv840xx0000/text_extraction/new'

        # these buttons are disabled since object is locked
        expect(page).to have_css 'a.disabled', text: 'Create embargo'
        expect(page).to have_css 'a.disabled', text: 'Apply APO defaults'

        expect(rendered.css('a').size).to eq(9)
        expect(rendered.css('a.disabled').size).to eq 4 # create embargo, apply APO defaults, purge, republish
      end
    end

    context 'when the object is in accessioning' do
      let(:open) { false }
      let(:processing_status) { 'V2 In accessioning' }

      it 'the text extraction button exists but is disabled' do
        expect(page).to have_link 'Text extraction', href: '/items/druid:kv840xx0000/text_extraction/new'
        expect(page).to have_css 'a.disabled', text: 'Text extraction'
      end
    end

    context 'when the object has workflow errors' do
      let(:open) { false }
      let(:workflow_errors) { 'ocrWF:ocr-create:bad stuff' }

      it 'the text extraction button exists but is disabled' do
        expect(page).to have_link 'Text extraction', href: '/items/druid:kv840xx0000/text_extraction/new'
        expect(page).to have_css 'a.disabled', text: 'Text extraction'
      end
    end
  end

  context 'when the object is an AdminPolicy the user can manage' do
    let(:view_apo_id) { 'druid:zt570qh4444' }
    let(:open) { true }
    let(:dro) { false }

    let(:doc) do
      SolrDocument.new('id' => view_apo_id,
                       'processing_status_text_ssi' => 'not registered',
                       SolrDocument::FIELD_OBJECT_TYPE => 'adminPolicy',
                       SolrDocument::FIELD_APO_ID => [governing_apo_id])
    end

    it 'renders the appropriate buttons' do
      expect(page).to have_link 'Edit APO', href: '/apo/druid:zt570qh4444/edit'
      expect(page).to have_link 'Create Collection', href: '/apo/druid:zt570qh4444/collections/new'
      expect(page).to have_link 'Reindex', href: '/dor/reindex/druid:zt570qh4444'
      expect(page).to have_link 'Add workflow', href: '/items/druid:zt570qh4444/workflows/new'
      expect(page).to have_link 'Purge', href: '/items/druid:zt570qh4444/purge'
      expect(page).to have_link 'Upload MODS', href: '/apos/druid:zt570qh4444/bulk_jobs'
      expect(rendered.css("a.disabled[data-turbo-confirm][data-turbo-method='delete']").inner_text).to eq 'Purge'
      expect(rendered.css("a[data-turbo-method='post'][href='/items/druid:zt570qh4444/apply_apo_defaults']").size).to eq 0 # no apply APO defaults for APOs
      expect(page).to have_no_link 'Republish'
      expect(page).to have_no_link 'Manage release'

      expect(rendered.css('a').size).to eq 6
    end
  end

  context 'when the object is a Collection the user can manage' do
    let(:view_collection_id) { 'druid:kv840xx0000' }
    let(:open) { true }
    let(:dro) { false }

    let(:doc) do
      SolrDocument.new('id' => view_collection_id,
                       'processing_status_text_ssi' => 'not registered',
                       SolrDocument::FIELD_OBJECT_TYPE => 'collection',
                       CatalogRecordId.index_field => catalog_record_id,
                       SolrDocument::FIELD_APO_ID => [governing_apo_id])
    end
    let(:catalog_record_id) { nil }

    it 'renders the appropriate buttons' do
      expect(page).to have_link 'Reindex', href: '/dor/reindex/druid:kv840xx0000'
      expect(page).to have_link 'Manage release', href: '/items/druid:kv840xx0000/manage_release'
      expect(page).to have_link 'Add workflow', href: '/items/druid:kv840xx0000/workflows/new'
      expect(page).to have_link 'Republish'
      expect(page).to have_text 'Manage description'
      expect(page).to have_link 'Purge', href: '/items/druid:kv840xx0000/purge'
      expect(page).to have_link 'Download Cocina spreadsheet', href: '/items/druid:kv840xx0000/descriptive.csv'
      expect(page).to have_link 'Upload Cocina spreadsheet', href: '/items/druid:kv840xx0000/descriptive/edit'

      expect(rendered.css('a').size).to eq(8)
    end

    context 'when the collection has a catalog record ID' do
      let(:catalog_record_id) { "#{CatalogRecordId.indexing_prefix}:1234567" }

      it 'includes the descriptive metadata refresh button without "Manage Serials" and the correct count of actions' do
        expect(page).to have_link 'Refresh', href: '/items/druid:kv840xx0000/refresh_metadata'
        expect(page).to have_no_link 'Manage serials', href: '/items/druid:kv840xx0000/serials/edit'

        expect(rendered.css('a').size).to eq(9)
      end
    end
  end

  describe '#registered_only?' do
    subject { component.send(:registered_only?) }

    let(:open) { true }
    let(:item_id) { 'druid:kv840xx0000' }
    let(:dro) { true }

    context 'when registered' do
      let(:doc) do
        SolrDocument.new(:id => item_id, 'processing_status_text_ssi' => 'Registered')
      end

      it { is_expected.to be true }
    end

    context 'when unknown' do
      let(:doc) do
        SolrDocument.new(:id => item_id, 'processing_status_text_ssi' => 'Unknown Status')
      end

      it { is_expected.to be true }
    end

    context 'when beyond registered only' do
      let(:doc) do
        SolrDocument.new(:id => item_id, 'processing_status_text_ssi' => 'In accessioning')
      end

      it { is_expected.to be false }
    end
  end

  describe '#in_accessioning?' do
    subject { component.send(:in_accessioning?) }

    let(:item_id) { 'druid:kv840xx0000' }
    let(:dro) { true }

    context 'when registered' do
      let(:open) { true }
      let(:doc) do
        SolrDocument.new(:id => item_id, 'processing_status_text_ssi' => 'Registered')
      end

      it { is_expected.to be false }
    end

    context 'when accessioned' do
      let(:open) { false }
      let(:doc) do
        SolrDocument.new(:id => item_id, 'processing_status_text_ssi' => 'V1 Accessioned')
      end

      it { is_expected.to be false }
    end

    context 'when unknown' do
      let(:open) { true }
      let(:doc) do
        SolrDocument.new(:id => item_id, 'processing_status_text_ssi' => 'Unknown Status')
      end

      it { is_expected.to be false }
    end

    context 'when in accessioning' do
      let(:open) { true }
      let(:doc) do
        SolrDocument.new(:id => item_id, 'processing_status_text_ssi' => 'V2 In accessioning')
      end

      it { is_expected.to be true }
    end
  end

  describe '#published?' do
    subject { component.send(:published?) }

    let(:item_id) { 'druid:kv840xx0000' }
    let(:dro) { true }
    let(:open) { false }

    context 'when published date' do
      let(:doc) do
        SolrDocument.new(:id => item_id, SolrDocument::FIELD_LAST_PUBLISHED_DATE => Time.zone.now)
      end

      it { is_expected.to be true }
    end

    context 'when not published date' do
      let(:doc) do
        SolrDocument.new(id: item_id)
      end

      it { is_expected.to be false }
    end
  end

  describe '#workflow_errors?' do
    subject { component.send(:workflow_errors?) }

    let(:item_id) { 'druid:kv840xx0000' }
    let(:dro) { true }
    let(:open) { false }

    context 'when workflow errors exist' do
      let(:doc) do
        SolrDocument.new(:id => item_id, SolrDocument::FIELD_WORKFLOW_ERRORS => 'ocrWF:ocr-create:bad stuff')
      end

      it { is_expected.to be true }
    end

    context 'when workflow errors do not exist' do
      let(:doc) do
        SolrDocument.new(id: item_id)
      end

      it { is_expected.to be false }
    end
  end
end
