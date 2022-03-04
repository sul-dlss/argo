# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show rights for an object' do
  context 'when they have manage access' do
    let(:user) { create(:user) }
    let(:pid) { 'druid:cc243mg0841' }
    let(:apo_pid) { 'druid:cg532dg5405' }

    let(:apo) do
      Cocina::Models.build({
                             'label' => 'My APO',
                             'version' => 1,
                             'type' => Cocina::Models::Vocab.admin_policy,
                             'externalIdentifier' => apo_pid,
                             'administrative' => {
                               'hasAdminPolicy' => apo_pid,
                               'hasAgreement' => 'druid:hp308wm0436',
                               'defaultAccess' => { 'access' => 'world', 'download' => 'world' }
                             }
                           })
    end
    let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model, update: true) }
    let(:apo_client) { instance_double(Dor::Services::Client::Object, find: apo) }

    before do
      allow(Dor::Services::Client).to receive(:object).with(pid).and_return(object_client)
      allow(Dor::Services::Client).to receive(:object).with(apo_pid).and_return(apo_client)

      allow(Argo::Indexer).to receive(:reindex_pid_remotely)
      sign_in user, groups: ['sdr:administrator-role']
    end

    context 'for a DRO' do
      let(:cocina_model) do
        Cocina::Models.build({
                               'label' => 'My ETD',
                               'version' => 1,
                               'type' => Cocina::Models::Vocab.object,
                               'externalIdentifier' => pid,
                               'description' => {
                                 'title' => [{ 'value' => 'My ETD' }],
                                 'purl' => "https://purl.stanford.edu/#{pid.delete_prefix('druid:')}"
                               },
                               'access' => {
                                 'access' => 'world',
                                 'download' => 'none',
                                 embargo: {
                                   releaseDate: '2021-02-11T00:00:00.000+00:00',
                                   access: 'world',
                                   download: 'world'
                                 }
                               },
                               'administrative' => { hasAdminPolicy: apo_pid },
                               'structural' => {
                                 'contains' => [
                                   {
                                     'externalIdentifier' => 'cc243mg0841_1',
                                     'label' => 'Fileset 1',
                                     'type' => 'http://cocina.sul.stanford.edu/models/resources/file.jsonld',
                                     'version' => 1,
                                     'structural' => {
                                       'contains' => [
                                         { 'externalIdentifier' => 'cc243mg0841_1',
                                           'label' => 'Page 1',
                                           'type' => 'http://cocina.sul.stanford.edu/models/file.jsonld',
                                           'version' => 1,
                                           'access' => { access: 'world', download: 'none' },
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
        get "/items/#{pid}/rights"
        expect(response).to be_successful
      end
    end

    context 'for a Collection' do
      let(:cocina_model) do
        Cocina::Models.build({
                               'label' => 'My ETD',
                               'version' => 1,
                               'type' => Cocina::Models::Vocab.collection,
                               'externalIdentifier' => pid,
                               'description' => {
                                 'title' => [{ 'value' => 'My ETD' }],
                                 'purl' => "https://purl.stanford.edu/#{pid.delete_prefix('druid:')}"
                               },
                               'access' => {
                                 'access' => 'world'
                               },
                               'administrative' => { hasAdminPolicy: apo_pid },
                               'identification' => {}
                             })
      end

      it 'draws the page' do
        get "/items/#{pid}/rights"
        expect(response).to be_successful
      end
    end

    context "when the cocina model isn't found" do
      let(:cocina_model) do
        Cocina::Models.build({
                               'label' => 'My ETD',
                               'version' => 1,
                               'type' => Cocina::Models::Vocab.collection,
                               'externalIdentifier' => pid,
                               'description' => {
                                 'title' => [{ 'value' => 'My ETD' }],
                                 'purl' => "https://purl.stanford.edu/#{pid.delete_prefix('druid:')}"
                               },
                               'access' => {
                                 'access' => 'world'
                               },
                               'administrative' => { hasAdminPolicy: apo_pid },
                               'identification' => {}
                             })
      end

      before do
        allow(object_client).to receive(:find)
          .and_raise(Dor::Services::Client::UnexpectedResponse, 'Error: ({"errors":[{"detail":"Invalid date"}]})')
      end

      it 'shows the error' do
        get "/items/#{pid}/rights"
        expect(flash[:error]).to eq 'Unable to retrieve the cocina model'
      end
    end
  end
end
