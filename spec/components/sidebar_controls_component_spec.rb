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
  let(:rendered) { render_inline(component) }
  let(:state_service) { instance_double(StateService, allows_modification?: true) }

  before do
    allow(StateService).to receive(:new).and_return(state_service)
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

    it 'creates a hash with the needed button info for an admin' do
      expect(rendered.css("a[href='/dor/reindex/druid:kv840xx0000']").inner_text).to eq 'Reindex'
      expect(rendered.css("a[href='/items/druid:kv840xx0000/workflows/new']").inner_text).to eq 'Add workflow'
      expect(rendered.css("a[href='/dor/republish/druid:kv840xx0000']").inner_text).to eq 'Republish'
      expect(rendered.css("a.disabled[data-turbo-confirm][data-turbo-method='delete'][href='/items/druid:kv840xx0000/purge']").inner_text).to eq 'Purge'
      expect(rendered.css("a[href='/items/druid:kv840xx0000/manage_release']").inner_text).to eq 'Manage release'
      expect(rendered.css("a[href='/items/druid:kv840xx0000/embargo/new']").inner_text).to eq 'Create embargo'
      expect(rendered.css('a').size).to eq 6
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
        expect(rendered.css('a').size).to eq 7
      end
    end
  end

  context 'when the object is an AdminPolicy the user can manage' do
    let(:view_apo_id) { 'druid:zt570qh4444' }

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
      expect(rendered.css("a.disabled[data-turbo-confirm][data-turbo-method='delete']").inner_text).to eq 'Purge'
      expect(page).not_to have_link 'Republish'
      expect(page).not_to have_link 'Manage release'

      expect(rendered.css('a').size).to eq 5
    end
  end

  describe '#registered_only?' do
    subject { component.send(:registered_only?) }

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
