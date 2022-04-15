# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::ControlsComponent, type: :component do
  let(:component) do
    described_class.new(manager: manager, presenter: presenter)
  end

  let(:url_helpers) { Rails.application.routes.url_helpers }
  let(:governing_apo_id) { 'druid:hv992yv2222' }
  let(:manager) { true }
  let(:rendered) { render_inline(component) }
  let(:presenter) { instance_double(ArgoShowPresenter, document: doc, allows_modification?: allows_modification) }

  before do
    rendered
  end

  context 'when the object is a DRO the user can manage and no catkey or embargo info' do
    let(:item_id) { 'druid:kv840xx0000' }

    let(:doc) do
      SolrDocument.new('id' => item_id,
                       'processing_status_text_ssi' => 'not registered',
                       SolrDocument::FIELD_OBJECT_TYPE => 'item',
                       SolrDocument::FIELD_CATKEY_ID => catkey,
                       SolrDocument::FIELD_APO_ID => [governing_apo_id])
    end
    let(:catkey) { nil }

    context 'when the object is unlocked' do
      let(:allows_modification) { true }

      it 'draws the buttons' do
        expect(page).to have_link 'Reindex', href: '/dor/reindex/druid:kv840xx0000'
        expect(page).to have_link 'Add workflow', href: '/items/druid:kv840xx0000/workflows/new'
        expect(page).to have_link 'Publish', href: '/items/druid:kv840xx0000/publish'
        expect(page).to have_link 'Unpublish', href: '/items/druid:kv840xx0000/publish'
        expect(rendered.css("a.disabled[data-turbo-confirm][data-turbo-method='delete'][href='/items/druid:kv840xx0000/purge']").inner_text).to eq 'Purge'
        expect(page).to have_link 'Manage release', href: '/items/druid:kv840xx0000/manage_release'
        expect(page).to have_link 'Create embargo', href: '/items/druid:kv840xx0000/embargo/new'
        expect(rendered.css("a[data-turbo-method='post'][href='/items/druid:kv840xx0000/apply_apo_defaults']").inner_text).to eq 'Apply APO defaults'
        expect(page).to have_link 'Download Cocina spreadsheet', href: '/items/druid:kv840xx0000/descriptive.csv'
        expect(page).to have_link 'Upload Cocina spreadsheet', href: '/items/druid:kv840xx0000/descriptive/edit'

        expect(rendered.css('a').size).to eq 10
        expect(rendered.css('a.disabled').size).to eq 3 # purge, publish/unpublish are disabled
      end

      context "with a user that can't manage the object" do
        let(:manager) { false }

        it 'does not generate errors given an object that has no associated APO' do
          expect(rendered.css('a').to_html).to eq ''
        end
      end

      context 'when the item has a catkey' do
        let(:catkey) { 'catkey:1234567' }

        it 'includes the descriptive metadata refresh button and the correct count of actions' do
          expect(page).to have_link 'Refresh', href: '/items/druid:kv840xx0000/refresh_metadata'
          expect(page).to have_link 'Manage serials', href: '/items/druid:kv840xx0000/serials/edit'

          expect(rendered.css('a').size).to eq 12
        end
      end
    end

    context 'when the object is locked' do
      let(:allows_modification) { false }

      it 'the embargo and apply APO buttons are disabled' do
        expect(page).to have_link 'Reindex', href: '/dor/reindex/druid:kv840xx0000'
        expect(page).to have_link 'Add workflow', href: '/items/druid:kv840xx0000/workflows/new'
        expect(page).to have_link 'Publish', href: '/items/druid:kv840xx0000/publish'
        expect(page).to have_link 'Unpublish', href: '/items/druid:kv840xx0000/publish'
        expect(rendered.css("a.disabled[data-turbo-confirm][data-turbo-method='delete'][href='/items/druid:kv840xx0000/purge']").inner_text).to eq 'Purge'
        expect(page).to have_link 'Manage release', href: '/items/druid:kv840xx0000/manage_release'
        expect(page).to have_link 'Download Cocina spreadsheet', href: '/items/druid:kv840xx0000/descriptive.csv'
        expect(page).to have_link 'Upload Cocina spreadsheet', href: '/items/druid:kv840xx0000/descriptive/edit'

        # these buttons are disabled since object is locked
        expect(page).to have_css 'a.disabled', text: 'Create embargo'
        expect(page).to have_css 'a.disabled', text: 'Apply APO defaults'

        expect(rendered.css('a').size).to eq 10
        expect(rendered.css('a.disabled').size).to eq 5 # create embargo, apply APO defaults, purge, publish/unpublish are disabled
      end
    end
  end

  context 'when the object is an AdminPolicy the user can manage' do
    let(:view_apo_id) { 'druid:zt570qh4444' }
    let(:allows_modification) { true }

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
      expect(page).not_to have_link 'Republish'
      expect(page).not_to have_link 'Manage release'

      expect(rendered.css('a').size).to eq 6
    end
  end

  context 'when the object is a Collection the user can manage' do
    let(:view_collection_id) { 'druid:kv840xx0000' }
    let(:allows_modification) { true }

    let(:doc) do
      SolrDocument.new('id' => view_collection_id,
                       'processing_status_text_ssi' => 'not registered',
                       SolrDocument::FIELD_OBJECT_TYPE => 'collection',
                       SolrDocument::FIELD_CATKEY_ID => catkey,
                       SolrDocument::FIELD_APO_ID => [governing_apo_id])
    end
    let(:catkey) { nil }

    it 'renders the appropriate buttons' do
      expect(page).to have_link 'Reindex', href: '/dor/reindex/druid:kv840xx0000'
      expect(page).to have_link 'Manage release', href: '/items/druid:kv840xx0000/manage_release'
      expect(page).to have_link 'Add workflow', href: '/items/druid:kv840xx0000/workflows/new'
      expect(page).to have_link 'Publish'
      expect(page).to have_link 'Unpublish'
      expect(page).to have_text 'Manage description'
      expect(page).to have_link 'Purge', href: '/items/druid:kv840xx0000/purge'
      expect(page).to have_link 'Download Cocina spreadsheet', href: '/items/druid:kv840xx0000/descriptive.csv'
      expect(page).to have_link 'Upload Cocina spreadsheet', href: '/items/druid:kv840xx0000/descriptive/edit'

      expect(rendered.css('a').size).to eq 9
    end

    context 'when the collection has a catkey' do
      let(:catkey) { 'catkey:1234567' }

      it 'includes the descriptive metadata refresh button without "Manage Serials" and the correct count of actions' do
        expect(page).to have_link 'Refresh', href: '/items/druid:kv840xx0000/refresh_metadata'
        expect(page).not_to have_link 'Manage serials', href: '/items/druid:kv840xx0000/serials/edit'

        expect(rendered.css('a').size).to eq 10
      end
    end
  end

  describe '#registered_only?' do
    subject { component.send(:registered_only?) }

    let(:allows_modification) { true }
    let(:item_id) { 'druid:kv840xx0000' }

    context 'when registered' do
      let(:doc) do
        SolrDocument.new(id: item_id, 'processing_status_text_ssi' => 'Registered')
      end

      it { is_expected.to be true }
    end

    context 'when unknown' do
      let(:doc) do
        SolrDocument.new(id: item_id, 'processing_status_text_ssi' => 'Unknown Status')
      end

      it { is_expected.to be true }
    end

    context 'when beyond registered only' do
      let(:doc) do
        SolrDocument.new(id: item_id, 'processing_status_text_ssi' => 'In accessioning')
      end

      it { is_expected.to be false }
    end
  end
end
