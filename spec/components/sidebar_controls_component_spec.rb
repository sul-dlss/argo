# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SidebarControlsComponent, type: :component do
  let(:component) do
    described_class.new(manager: manager,
                        solr_document: doc)
  end

  let(:url_helpers) { Rails.application.routes.url_helpers }
  let(:governing_apo_id) { 'druid:hv992yv2222' }
  let(:manager) { true }

  describe '#buttons' do
    let(:rendered) { render_inline(component) }
    let(:state_service) { instance_double(StateService, allows_modification?: true) }

    before do
      allow(StateService).to receive(:new).and_return(state_service)
    end

    context 'a DRO the user can manage, with the usual data streams, and no catkey or embargo info' do
      let(:item_id) { 'druid:kv840xx0000' }

      let(:doc) do
        SolrDocument.new('id' => item_id,
                         'processing_status_text_ssi' => 'not registered',
                         SolrDocument::FIELD_OBJECT_TYPE => 'item',
                         SolrDocument::FIELD_CATKEY_ID => catkey,
                         SolrDocument::FIELD_APO_ID => [governing_apo_id])
      end
      let(:catkey) { nil }

      it 'creates a hash with the needed button info for an admin' do
        expect(rendered.css("a.disabled[href='/items/druid:kv840xx0000/versions/close_ui'][data-button-check-url-value]").inner_text).to eq 'Close Version'
        expect(rendered.css("a.disabled[href='/items/druid:kv840xx0000/versions/open_ui'][data-button-check-url-value]").inner_text).to eq 'Open for modification'
        expect(rendered.css("a[href='/dor/reindex/druid:kv840xx0000']").inner_text).to eq 'Reindex'
        expect(rendered.css("a[href='/items/druid:kv840xx0000/set_governing_apo_ui']").inner_text).to eq 'Set governing APO'
        expect(rendered.css("a[href='/items/druid:kv840xx0000/workflows/new']").inner_text).to eq 'Add workflow'
        expect(rendered.css("a[href='/dor/republish/druid:kv840xx0000']").inner_text).to eq 'Republish'
        expect(rendered.css("a.disabled[data-turbo-confirm][data-turbo-method='delete'][href='/items/druid:kv840xx0000/purge']").inner_text).to eq 'Purge'
        expect(rendered.css("a[href='/items/druid:kv840xx0000/source_id_ui']").inner_text).to eq 'Change source id'
        expect(rendered.css("a[href='/items/druid:kv840xx0000/catkey/edit']").inner_text).to eq 'Manage catkey'
        expect(rendered.css("a[href='/items/druid:kv840xx0000/tags/edit']").inner_text).to eq 'Edit tags'
        expect(rendered.css("a[href='/items/druid:kv840xx0000/collection_ui']").inner_text).to eq 'Edit collections'
        expect(rendered.css("a[href='/items/druid:kv840xx0000/content_type']").inner_text).to eq 'Set content type'
        expect(rendered.css("a[href='/items/druid:kv840xx0000/rights']").inner_text).to eq 'Set rights'
        expect(rendered.css("a[href='/items/druid:kv840xx0000/manage_release']").inner_text).to eq 'Manage release'
        expect(rendered.css("a[href='/items/druid:kv840xx0000/embargo/new']").inner_text).to eq 'Create embargo'
        expect(rendered.css('a').size).to eq 15
      end

      it 'only includes the embargo update button if the user is an admin and the object is embargoed' do
        allow(doc).to receive(:embargoed?).and_return(true)
        expect(rendered.css("a[href='/items/druid:kv840xx0000/embargo/edit']").inner_text).to eq 'Manage embargo'
        expect(rendered.css('a').size).to eq 15
      end

      context "with a user that can't manage the object" do
        let(:manager) { false }

        it 'does not generate errors given an object that has no associated APO' do
          expect(rendered.css('a').to_html).to eq ''
        end
      end

      context 'when the item has a catkey' do
        let(:catkey) { 'catkey:1234567' }

        it 'includes the refresh descMetadata button' do
          expect(rendered.css("a[href='/items/druid:kv840xx0000/refresh_metadata']").inner_text).to eq 'Refresh descMetadata'
          expect(rendered.css('a').size).to eq 16
        end
      end
    end

    context 'an AdminPolicy the user can manage' do
      let(:view_apo_id) { 'druid:zt570qh4444' }

      let(:doc) do
        SolrDocument.new('id' => view_apo_id,
                         'processing_status_text_ssi' => 'not registered',
                         SolrDocument::FIELD_OBJECT_TYPE => 'adminPolicy',
                         SolrDocument::FIELD_APO_ID => [governing_apo_id])
      end

      it 'renders the appropriate default buttons for an apo' do
        expect(rendered.css("a.disabled[href='/items/druid:zt570qh4444/versions/close_ui'][data-button-check-url-value]").inner_text).to eq 'Close Version'
        expect(rendered.css("a.disabled[href='/items/druid:zt570qh4444/versions/open_ui'][data-button-check-url-value]").inner_text).to eq 'Open for modification'
        expect(rendered.css("a[href='/apo/druid:zt570qh4444/edit']").inner_text).to eq 'Edit APO'
        expect(rendered.css("a[href='/apo/druid:zt570qh4444/collections/new']").inner_text).to eq 'Create Collection'
        expect(rendered.css("a[href='/dor/reindex/druid:zt570qh4444']").inner_text).to eq 'Reindex'
        expect(rendered.css("a[href='/items/druid:zt570qh4444/set_governing_apo_ui']").inner_text).to eq 'Set governing APO'
        expect(rendered.css("a[href='/items/druid:zt570qh4444/workflows/new']").inner_text).to eq 'Add workflow'
        expect(rendered.css("a[href='/dor/republish/druid:zt570qh4444']").inner_text).to eq 'Republish'
        expect(rendered.css("a.disabled[data-turbo-confirm][data-turbo-method='delete'][href='/items/druid:zt570qh4444/purge']").inner_text).to eq 'Purge'
        expect(rendered.css("a[href='/items/druid:zt570qh4444/tags/edit']").inner_text).to eq 'Edit tags'
        expect(rendered.css("a[href='/items/druid:zt570qh4444/manage_release']").inner_text).to eq 'Manage release'
        expect(rendered.css('a').size).to eq 11
      end
    end
  end

  describe '#registered_only?' do
    subject { component.send(:registered_only?) }

    let(:item_id) { 'druid:kv840xx0000' }

    context 'when registered' do
      let(:doc) do
        SolrDocument.new('processing_status_text_ssi' => 'Registered')
      end

      it { is_expected.to be true }
    end

    context 'when unknown' do
      let(:doc) do
        SolrDocument.new('processing_status_text_ssi' => 'Unknown Status')
      end

      it { is_expected.to be true }
    end

    context 'when beyond registered only' do
      let(:doc) do
        SolrDocument.new('processing_status_text_ssi' => 'In accessioning')
      end

      it { is_expected.to be false }
    end
  end
end
