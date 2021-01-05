# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Viewing an Admin policy' do
  let(:object) { Dor::AdminPolicyObject.new(pid: 'druid:zt570tx3016') }
  let(:current_user) { create(:user) }
  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model) }
  let(:pid) { 'druid:zt570tx3016' }
  let(:cocina_model) do
    Cocina::Models.build(
      'label' => 'The APO',
      'version' => 1,
      'type' => Cocina::Models::Vocab.admin_policy,
      'externalIdentifier' => pid,
      'administrative' => { hasAdminPolicy: 'druid:hv992ry2431' }
    )
  end

  let(:solr_doc) { { id: pid } }

  before do
    ActiveFedora::SolrService.add(solr_doc)
    ActiveFedora::SolrService.commit
    sign_in current_user, groups: ['sdr:administrator-role']
    allow(object).to receive(:persisted?).and_return(true) # This allows to_param to function
    allow(Dor).to receive(:find).and_return(object)
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
  end

  context 'mods view' do
    before do
      allow(Dor::Services::Client).to receive(:object).with('druid:zt570tx3016').and_return(object_service)
    end

    let(:object_service) { instance_double(Dor::Services::Client::Object, metadata: metadata_service) }
    let(:metadata_service) { instance_double(Dor::Services::Client::Metadata, descriptive: xml) }
    let(:xml) do
      <<~XML
        <mods version="3.6" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <titleInfo lang="eng" script="Latn"><title>Ampex</title></titleInfo>
        </mods>
      XML
    end

    it 'renders the mods view including a title' do
      visit '/items/druid:zt570tx3016/purl_preview'
      expect(page).to have_content('Ampex')
    end
  end

  context 'item dialogs' do
    context 'open version ui' do
      it 'renders the open version ui' do
        visit '/items/druid:zt570tx3016/versions/open_ui'
        expect(page).to have_content('description')
      end
    end

    context 'close version ui' do
      it 'renders the close version ui' do
        visit '/items/druid:zt570tx3016/versions/close_ui'
        expect(page).to have_content('description')
      end
    end

    context 'add workflow' do
      let(:workflow_client) { instance_double(Dor::Workflow::Client, workflow_templates: []) }

      before do
        allow(Dor::Workflow::Client).to receive(:new).and_return(workflow_client)
      end

      it 'renders the add workflow ui' do
        visit new_item_workflow_path('druid:zt570tx3016')
        expect(page).to have_content('Add workflow')
      end
    end

    context 'open version ui' do
      it 'renders the add collection ui' do
        allow(current_user).to receive(:permitted_collections).and_return(['druid:ab123cd4567'])
        visit '/items/druid:zt570tx3016/collection_ui'
        expect(page).to have_content('Add Collection')
      end
    end

    context 'content type' do
      it 'renders the edit content type ui' do
        visit '/items/druid:zt570tx3016/content_type'
        expect(page).to have_content('Set content type')
      end
    end

    context 'embargo form' do
      it 'renders the embargo update ui' do
        visit '/items/druid:zt570tx3016/embargo_form'
        expect(page).to have_content('Embargo')
      end
    end

    context 'source id ui' do
      it 'renders the source id update ui' do
        idmd = double(Dor::IdentityMetadataDS)
        allow(object).to receive(:identityMetadata).and_return(idmd)
        allow(idmd).to receive(:sourceId).and_return('something123')
        visit '/items/druid:zt570tx3016/source_id_ui'
        expect(page).to have_content('Update')
      end
    end

    context 'tag ui' do
      let(:tags_client) { instance_double(Dor::Services::Client::AdministrativeTags, list: []) }
      let(:object_client) do
        instance_double(Dor::Services::Client::Object, find: cocina_model, administrative_tags: tags_client)
      end

      it 'renders the tag ui' do
        visit '/items/druid:zt570tx3016/tags/edit'
        expect(page).to have_content('Update tags')
      end
    end
  end
end
