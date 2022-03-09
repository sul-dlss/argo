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
    Cocina::Models.build({
                           'label' => 'The APO',
                           'version' => 1,
                           'type' => Cocina::Models::ObjectType.admin_policy,
                           'externalIdentifier' => apo_druid,
                           'administrative' => {
                             hasAdminPolicy: 'druid:hv992ry2431',
                             hasAgreement: 'druid:hp308wm0436',
                             accessTemplate: { view: 'world', download: 'world' }
                           }
                         })
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

  context 'item dialogs' do
    context 'open version ui' do
      it 'renders the open version ui' do
        visit "/items/#{apo_druid}/versions/open_ui"
        expect(page).to have_content('description')
      end
    end

    context 'close version ui' do
      it 'renders the close version ui' do
        visit "/items/#{apo_druid}/versions/close_ui"
        expect(page).to have_content('description')
      end
    end

    context 'add workflow' do
      let(:workflow_client) { instance_double(Dor::Workflow::Client, workflow_templates: []) }

      before do
        allow(Dor::Workflow::Client).to receive(:new).and_return(workflow_client)
      end

      it 'renders the add workflow ui' do
        visit new_item_workflow_path(apo_druid)
        expect(page).to have_content('Add workflow')
      end
    end

    context 'open version ui' do
      let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model, collections: []) }

      it 'renders the add collection ui' do
        allow(current_user).to receive(:permitted_collections).and_return(['druid:ab123cd4567'])
        visit "/items/#{apo_druid}/collection_ui"
        expect(page).to have_content('Add Collection')
      end
    end

    context 'content type' do
      it 'renders the edit content type ui' do
        visit "/items/#{apo_druid}/content_type"
        expect(page).to have_content('Set content type')
      end
    end

    context 'tag ui' do
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
