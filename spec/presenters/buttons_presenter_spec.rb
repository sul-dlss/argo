# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ButtonsPresenter, type: :presenter do
  let(:presenter) do
    described_class.new(ability: ability,
                        solr_document: doc,
                        object: object)
  end

  let(:url_helpers) { Rails.application.routes.url_helpers }
  let(:ability) { Ability.new(user) }
  let(:user) do
    instance_double(User,
                    admin?: true,
                    webauth_admin?: false,
                    manager?: false,
                    viewer?: false,
                    roles: false)
  end

  let(:governing_apo_id) { 'druid:hv992ry2431' }
  let(:doc) do
    SolrDocument.new('id' => item_id,
                     'processing_status_text_ssi' => 'not registered',
                     SolrDocument::FIELD_APO_ID => [governing_apo_id])
  end

  describe '#buttons' do
    let(:state_service) { instance_double(StateService, allows_modification?: true) }

    before do
      allow(StateService).to receive(:new).and_return(state_service)
    end

    context 'a Dor::Item the user can manage, with the usual data streams, and no catkey or embargo info' do
      subject(:buttons) { presenter.buttons }

      let(:id_md) do
        instance_double(Dor::IdentityMetadataDS, ng_xml: Nokogiri::XML('<identityMetadata><identityMetadata>'),
                                                 otherId: [])
      end
      let(:desc_md) { instance_double(Dor::DescMetadataDS, new?: true) }
      let(:item_id) { 'druid:kv840xx0000' }
      let(:governing_apo) { instance_double(Dor::AdminPolicyObject, pid: governing_apo_id) }
      let(:object) do
        instance_double(Dor::Item, identityMetadata: id_md, pid: item_id, current_version: '3',
                                   admin_policy_object: governing_apo,
                                   embargoed?: false,
                                   datastreams: { 'contentMetadata' => nil, 'rightsMetadata' => nil, 'descMetadata' => desc_md, 'identityMetadata' => id_md })
      end

      let(:default_buttons) do
        [
          {
            label: 'Close Version',
            url: "/items/#{item_id}/versions/close_ui",
            check_url: "/workflow_service/#{item_id}/closeable"
          },
          {
            label: 'Open for modification',
            url: "/items/#{item_id}/versions/open_ui",
            check_url: "/workflow_service/#{item_id}/openable"
          },
          {
            label: 'Reindex',
            url: "/dor/reindex/#{item_id}",
            new_page: true
          },
          {
            label: 'Set governing APO',
            url: "/items/#{item_id}/set_governing_apo_ui",
            disabled: false
          },
          {
            label: 'Add workflow',
            url: url_helpers.new_item_workflow_path(item_id)
          },
          {
            label: 'Republish',
            url: "/dor/republish/#{item_id}",
            check_url: "/workflow_service/#{item_id}/published",
            new_page: true
          },
          {
            label: 'Purge',
            url: "/items/#{item_id}/purge",
            new_page: true,
            method: 'delete',
            confirm: 'This object will be permanently purged from DOR. This action cannot be undone. Are you sure?',
            disabled: true
          },
          {
            label: 'Change source id',
            url: "/items/#{item_id}/source_id_ui"
          },
          {
            label: 'Manage catkey',
            url: "/items/#{item_id}/catkey_ui"
          },
          {
            label: 'Edit tags',
            url: "/items/#{item_id}/tags/edit"
          },
          {
            label: 'Edit collections',
            url: "/items/#{item_id}/collection_ui"
          },
          {
            label: 'Set content type',
            url: "/items/#{item_id}/content_type"
          },
          {
            label: 'Set rights',
            url: "/items/#{item_id}/rights"
          },
          {
            label: 'Manage release',
            url: "/items/#{item_id}/manage_release"
          }
        ]
      end

      before do
        allow(object).to receive(:is_a?).and_return(false)
        allow(object).to receive(:is_a?).with(Dor::Item).and_return(true)
      end

      it 'creates a hash with the needed button info for an admin' do
        default_buttons.each do |button|
          expect(buttons).to include(button)
        end
        expect(buttons.length).to eq default_buttons.length
      end

      it 'generates the same button set for a non Dor-wide admin with APO specific mgmt privileges' do
        allow(user).to receive(:admin?).and_return(false)
        allow(ability).to receive(:can?).with(:manage_item, object).and_return(true)
        default_buttons.each do |button|
          expect(buttons).to include(button)
        end
        expect(buttons.length).to eq default_buttons.length
      end

      it 'only includes the embargo update button if the user is an admin and the object is embargoed' do
        allow(object).to receive(:embargoed?).and_return(true)
        default_buttons.push(
          label: 'Update embargo',
          url: "/items/#{item_id}/embargo_form"
        ).each do |button|
          expect(buttons).to include(button)
        end
        expect(buttons.length).to eq default_buttons.length
      end

      it "does not generate errors given an object that has no associated APO and a user that can't manage the object" do
        allow(user).to receive(:admin?).and_return(false)
        allow(doc).to receive(:apo_pid).and_return(nil)
        allow(object).to receive(:admin_policy_object).and_return(nil)
        allow(user).to receive(:roles).with(nil).and_return([])
        expect(buttons).not_to be_nil
        expect(buttons.length).to eq 0
      end

      it 'includes the refresh descMetadata button for items with catkey' do
        allow(id_md).to receive(:otherId).with('catkey').and_return(['1234567'])
        default_buttons.push(
          label: 'Refresh descMetadata',
          method: 'post',
          url: "/items/#{item_id}/refresh_metadata",
          new_page: true,
          disabled: false
        ).each do |button|
          expect(buttons).to include(button)
        end
        expect(buttons.length).to eq default_buttons.length
      end
    end

    context 'a Dor::AdminPolicyObject the user can manage' do
      let(:view_apo_id) { 'druid:zt570tx3016' }
      let(:object) { instantiate_fixture(view_apo_id, Dor::AdminPolicyObject) }
      let(:doc) do
        SolrDocument.new('id' => view_apo_id,
                         'processing_status_text_ssi' => 'not registered',
                         SolrDocument::FIELD_APO_ID => [governing_apo_id])
      end

      let(:default_buttons) do
        [
          {
            label: 'Close Version',
            url: "/items/#{view_apo_id}/versions/close_ui",
            check_url: "/workflow_service/#{view_apo_id}/closeable"
          },
          {
            label: 'Open for modification',
            url: "/items/#{view_apo_id}/versions/open_ui",
            check_url: "/workflow_service/#{view_apo_id}/openable"
          },
          {
            label: 'Edit APO',
            url: url_helpers.edit_apo_path(view_apo_id),
            new_page: true
          },
          {
            label: 'Create Collection',
            url: url_helpers.new_apo_collection_path(view_apo_id)
          },
          {
            label: 'Reindex',
            url: "/dor/reindex/#{view_apo_id}",
            new_page: true
          },
          {
            label: 'Set governing APO',
            url: "/items/#{view_apo_id}/set_governing_apo_ui",
            disabled: false
          },
          {
            label: 'Add workflow',
            url: url_helpers.new_item_workflow_path(view_apo_id)
          },
          {
            label: 'Republish',
            url: "/dor/republish/#{view_apo_id}",
            check_url: "/workflow_service/#{view_apo_id}/published",
            new_page: true
          },
          {
            label: 'Purge',
            url: "/items/#{view_apo_id}/purge",
            new_page: true,
            method: 'delete',
            confirm: 'This object will be permanently purged from DOR. This action cannot be undone. Are you sure?',
            disabled: true
          },
          {
            label: 'Change source id',
            url: "/items/#{view_apo_id}/source_id_ui"
          },
          {
            label: 'Edit tags',
            url: "/items/#{view_apo_id}/tags/edit"
          },
          {
            label: 'Manage release',
            url: "/items/#{view_apo_id}/manage_release"
          }
        ]
      end

      it 'renders the appropriate default buttons for an apo' do
        buttons = presenter.buttons
        default_buttons.each do |button|
          expect(buttons).to include(button)
        end
        expect(buttons.length).to eq default_buttons.length
      end
    end
  end

  describe '#registered_only?' do
    subject { presenter.send(:registered_only?) }

    let(:id_md) do
      instance_double(Dor::IdentityMetadataDS)
    end
    let(:item_id) { 'druid:kv840xx0000' }
    let(:object) { instance_double(Dor::Item, identityMetadata: id_md, pid: item_id, current_version: '3') }

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
