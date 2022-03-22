# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show rights for an object' do
  context 'when they have manage access' do
    let(:user) { create(:user) }
    let(:druid) { 'druid:cc243mg0841' }
    let(:apo_druid) { 'druid:cg532dg5405' }

    let(:apo) do
      Cocina::Models.build({
                             'label' => 'My APO',
                             'version' => 1,
                             'type' => Cocina::Models::ObjectType.admin_policy,
                             'externalIdentifier' => apo_druid,
                             'administrative' => {
                               'hasAdminPolicy' => apo_druid,
                               'hasAgreement' => 'druid:hp308wm0436',
                               'accessTemplate' => { 'view' => 'world', 'download' => 'world' }
                             }
                           })
    end
    let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model, update: true) }
    let(:apo_client) { instance_double(Dor::Services::Client::Object, find: apo) }

    before do
      allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
      allow(Dor::Services::Client).to receive(:object).with(apo_druid).and_return(apo_client)

      allow(Argo::Indexer).to receive(:reindex_druid_remotely)
      sign_in user, groups: ['sdr:administrator-role']
    end

    context 'for a DRO' do
      let(:cocina_model) do
        Cocina::Models.build({
                               'label' => 'My ETD',
                               'version' => 1,
                               'type' => Cocina::Models::ObjectType.object,
                               'externalIdentifier' => druid,
                               'description' => {
                                 'title' => [{ 'value' => 'My ETD' }],
                                 'purl' => "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}"
                               },
                               'access' => {
                                 'view' => 'world',
                                 'download' => 'none',
                                 embargo: {
                                   releaseDate: '2021-02-11T00:00:00.000+00:00',
                                   view: 'world',
                                   download: 'world'
                                 }
                               },
                               'administrative' => { hasAdminPolicy: apo_druid },
                               'structural' => {
                                 'contains' => [
                                   {
                                     'externalIdentifier' => 'cc243mg0841_1',
                                     'label' => 'Fileset 1',
                                     'type' => Cocina::Models::FileSetType.file,
                                     'version' => 1,
                                     'structural' => {
                                       'contains' => [
                                         { 'externalIdentifier' => 'cc243mg0841_1',
                                           'label' => 'Page 1',
                                           'type' => Cocina::Models::ObjectType.file,
                                           'version' => 1,
                                           'access' => { view: 'world', download: 'none' },
                                           'administrative' => {
                                             'publish' => true,
                                             'shelve' => true,
                                             'sdrPreserve' => true
                                           },
                                           'hasMessageDigests' => [],
                                           'filename' => 'page1.txt' }
                                       ]
                                     }
                                   }
                                 ]
                               },
                               'identification' => {}
                             })
      end

      it 'draws the page' do
        get "/items/#{druid}/rights"
        expect(response).to be_successful
      end
    end

    context 'for a Collection' do
      let(:cocina_model) do
        Cocina::Models.build({
                               'label' => 'My ETD',
                               'version' => 1,
                               'type' => Cocina::Models::ObjectType.collection,
                               'externalIdentifier' => druid,
                               'description' => {
                                 'title' => [{ 'value' => 'My ETD' }],
                                 'purl' => "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}"
                               },
                               'access' => {
                                 'view' => 'world'
                               },
                               'administrative' => { hasAdminPolicy: apo_druid },
                               'identification' => {}
                             })
      end

      it 'draws the page' do
        get "/items/#{druid}/rights"
        expect(response).to be_successful
      end
    end

    context "when the cocina model isn't found" do
      let(:cocina_model) do
        Cocina::Models.build({
                               'label' => 'My ETD',
                               'version' => 1,
                               'type' => Cocina::Models::ObjectType.collection,
                               'externalIdentifier' => druid,
                               'description' => {
                                 'title' => [{ 'value' => 'My ETD' }],
                                 'purl' => "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}"
                               },
                               'access' => {
                                 'view' => 'world'
                               },
                               'administrative' => { hasAdminPolicy: apo_druid },
                               'identification' => {}
                             })
      end

      before do
        allow(object_client).to receive(:find)
          .and_raise(Dor::Services::Client::UnexpectedResponse, 'Error: ({"errors":[{"detail":"Invalid date"}]})')
      end

      it 'shows the error' do
        get "/items/#{druid}/rights"
        expect(flash[:error]).to eq 'Unable to retrieve the cocina model'
      end
    end
  end
end
