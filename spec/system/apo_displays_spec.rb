# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Viewing an Admin policy' do
  let(:apo_druid) { 'druid:zt570qh4444' }
  let(:current_user) { create(:user) }
  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model, version: version_client) }
  let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, inventory: versions) }
  let(:versions) do
    [
      Dor::Services::Client::ObjectVersion::Version.new(message: 'description 1'),
      Dor::Services::Client::ObjectVersion::Version.new(message: 'description 2')
    ]
  end
  let(:cocina_model) do
    build(:admin_policy_with_metadata)
  end

  let(:solr_doc) { { id: apo_druid } }
  let(:blacklight_config) { CatalogController.blacklight_config }
  let(:solr_conn) { blacklight_config.repository_class.new(blacklight_config).connection }

  before do
    solr_conn.add(solr_doc)
    solr_conn.commit
    sign_in current_user, groups: ['sdr:administrator-role']
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
  end

  describe 'item dialogs' do
    context 'for open version ui' do
      it 'renders the open version ui' do
        visit "/items/#{apo_druid}/version/open_ui"
        expect(page).to have_content('description')
      end
    end

    context 'for close version ui' do
      it 'renders the close version ui' do
        visit "/items/#{apo_druid}/version/close_ui"
        expect(page).to have_content('description')
      end
    end

    context 'for add workflow' do
      it 'renders the add workflow ui' do
        visit new_item_workflow_path(apo_druid)
        expect(page).to have_content('Add workflow')
      end
    end

    context 'for open collection ui' do
      let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model, collections: []) }

      it 'renders the add collection ui' do
        allow(current_user).to receive(:permitted_collections).and_return(['druid:ab123cd4567'])
        visit "/items/#{apo_druid}/collection_ui"
        expect(page).to have_content('Add Collection')
      end
    end

    context 'for tag ui' do
      let(:tags_client) { instance_double(Dor::Services::Client::AdministrativeTags, list: []) }
      let(:object_client) do
        instance_double(Dor::Services::Client::Object, find: cocina_model, administrative_tags: tags_client)
      end

      it 'renders the tag ui' do
        visit "/items/#{apo_druid}/tags/edit"
        expect(page).to have_content('Save')
      end
    end
  end
end
