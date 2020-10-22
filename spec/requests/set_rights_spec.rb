# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Set rights for an object' do
  context 'when they have manage access' do
    let(:user) { create(:user) }
    let(:pid) { 'druid:cc243mg0841' }
    let(:fedora_obj) { instance_double(Dor::Item, pid: pid, current_version: 1, admin_policy_object: nil) }
    let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model, update: true) }

    before do
      allow(Dor).to receive(:find).and_return(fedora_obj)
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
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
                               'access' => {
                                 'access' => 'world',
                                 "embargo": {
                                   "releaseDate": '2021-02-11T00:00:00.000+00:00',
                                   "access": 'world'
                                 }
                               },
                               'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
                               'structural' => {
                                 'contains' => [
                                   {
                                     'externalIdentifier' => 'cc243mg0841_1',
                                     'label' => 'Fileset 1',
                                     'type' => 'http://cocina.sul.stanford.edu/models/fileset.jsonld',
                                     'version' => 1,
                                     'structural' => {
                                       'contains' => [
                                         { 'externalIdentifier' => 'cc243mg0841_1',
                                           'label' => 'Page 1',
                                           'type' => 'http://cocina.sul.stanford.edu/models/file.jsonld',
                                           'version' => 1,
                                           'access' => { access: 'world' },
                                           'administrative' => {
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

      context 'when setting dark access' do
        let(:updated_model) do
          cocina_model.new(
            {
              'access' => {
                'access' => 'dark',
                'download' => 'none',
                'controlledDigitalLending' => false,
                "embargo": {
                  "releaseDate": '2021-02-11T00:00:00.000+00:00',
                  "access": 'world'
                }
              },
              'structural' => {
                'contains' => [
                  {
                    'externalIdentifier' => 'cc243mg0841_1',
                    'label' => 'Fileset 1',
                    'type' => 'http://cocina.sul.stanford.edu/models/fileset.jsonld',
                    'version' => 1,
                    'structural' => {
                      'contains' => [
                        {
                          'externalIdentifier' => 'cc243mg0841_1',
                          'label' => 'Page 1',
                          'type' => 'http://cocina.sul.stanford.edu/models/file.jsonld',
                          'version' => 1,
                          'access' => { access: 'dark' },
                          'administrative' => { 'shelve' => false },
                          'filename' => 'page1.txt'
                        }
                      ]
                    }
                  }
                ]
              }
            }
          )
        end

        it 'sets the access and propagates changes to content metadata' do
          post "/items/#{pid}/set_rights", params: { dro_rights_form: { rights: 'dark' } }
          expect(response).to redirect_to(solr_document_path(pid))
          expect(object_client).to have_received(:update)
            .with(params: updated_model)
          expect(Argo::Indexer).to have_received(:reindex_pid_remotely).with(pid)
        end
      end

      context 'when setting stanford-only access' do
        let(:updated_model) do
          cocina_model.new(
            {
              'access' => {
                'access' => 'stanford',
                'download' => 'stanford',
                'controlledDigitalLending' => false,
                'embargo' => {
                  'releaseDate' => '2021-02-11T00:00:00.000+00:00',
                  'access' => 'world'
                }
              }
            }
          )
        end

        it 'sets the access and does not change content metadata' do
          post "/items/#{pid}/set_rights", params: { dro_rights_form: { rights: 'stanford' } }
          expect(response).to redirect_to(solr_document_path(pid))
          expect(object_client).to have_received(:update)
            .with(params: updated_model)
          expect(Argo::Indexer).to have_received(:reindex_pid_remotely).with(pid)
        end
      end

      context 'when setting cdl access' do
        let(:updated_model) do
          cocina_model.new(
            {
              'access' => {
                'access' => 'citation-only',
                'download' => 'none',
                'controlledDigitalLending' => true,
                'embargo' => {
                  'releaseDate' => '2021-02-11T00:00:00.000+00:00',
                  'access' => 'world'
                }
              }
            }
          )
        end

        it 'sets the access' do
          post "/items/#{pid}/set_rights", params: { dro_rights_form: { rights: 'cdl-stanford-nd' } }
          expect(response).to redirect_to(solr_document_path(pid))
          expect(object_client).to have_received(:update)
            .with(params: updated_model)
          expect(Argo::Indexer).to have_received(:reindex_pid_remotely).with(pid)
        end
      end

      context 'when removing cdl access' do
        let(:cocina_model) do
          Cocina::Models.build({
                                 'label' => 'My ETD',
                                 'version' => 1,
                                 'type' => Cocina::Models::Vocab.object,
                                 'externalIdentifier' => pid,
                                 'access' => {
                                   'access' => 'citation-only',
                                   'download' => 'none',
                                   'controlledDigitalLending' => true,
                                   'embargo' => {
                                     "releaseDate": '2021-02-11T00:00:00.000+00:00',
                                     "access": 'world'
                                   }
                                 },
                                 'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
                                 'structural' => {
                                   'contains' => [
                                     {
                                       'externalIdentifier' => 'cc243mg0841_1',
                                       'label' => 'Fileset 1',
                                       'type' => 'http://cocina.sul.stanford.edu/models/fileset.jsonld',
                                       'version' => 1,
                                       'structural' => {
                                         'contains' => [
                                           { 'externalIdentifier' => 'cc243mg0841_1',
                                             'label' => 'Page 1',
                                             'type' => 'http://cocina.sul.stanford.edu/models/file.jsonld',
                                             'version' => 1,
                                             'access' => { access: 'world' },
                                             'administrative' => {
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

        let(:updated_model) do
          cocina_model.new(
            {
              'access' => {
                'access' => 'world',
                'download' => 'world',
                'controlledDigitalLending' => false,
                'embargo' => {
                  'releaseDate' => '2021-02-11T00:00:00.000+00:00',
                  'access' => 'world'
                }
              }
            }
          )
        end

        it 'sets the access' do
          post "/items/#{pid}/set_rights", params: { dro_rights_form: { rights: 'world' } }
          expect(response).to redirect_to(solr_document_path(pid))
          expect(object_client).to have_received(:update)
            .with(params: updated_model)
          expect(Argo::Indexer).to have_received(:reindex_pid_remotely).with(pid)
        end
      end
    end

    context 'for a Collection' do
      let(:cocina_model) do
        Cocina::Models.build({
                               'label' => 'My ETD',
                               'version' => 1,
                               'type' => Cocina::Models::Vocab.collection,
                               'externalIdentifier' => pid,
                               'access' => {
                                 'access' => 'world'
                               },
                               'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
                               'identification' => {}
                             })
      end

      context 'when setting dark access' do
        let(:updated_model) do
          cocina_model.new(
            {
              'access' => {
                'access' => 'dark'
              }
            }
          )
        end

        it 'sets the access' do
          post "/items/#{pid}/set_rights", params: { collection_rights_form: { rights: 'dark' } }
          expect(response).to redirect_to(solr_document_path(pid))
          expect(object_client).to have_received(:update)
            .with(params: updated_model)
          expect(Argo::Indexer).to have_received(:reindex_pid_remotely).with(pid)
        end
      end

      context 'when setting an object to stanford-only' do
        let(:updated_model) do
          cocina_model.new(
            {
              'access' => {
                'access' => 'stanford'
              }
            }
          )
        end

        it 'sets the access' do
          post "/items/#{pid}/set_rights", params: { collection_rights_form: { rights: 'stanford' } }
          expect(response).to redirect_to(solr_document_path(pid))
          expect(object_client).to have_received(:update)
            .with(params: updated_model)
          expect(Argo::Indexer).to have_received(:reindex_pid_remotely).with(pid)
        end
      end

      context 'when a bulk request' do
        let(:updated_model) do
          cocina_model.new(
            {
              'access' => {
                'access' => 'stanford'
              }
            }
          )
        end

        it 'sets the access' do
          post "/items/#{pid}/set_rights", params: { bulk: true, dro_rights_form: { rights: 'stanford' } }
          expect(response).to have_http_status(:ok)
          expect(object_client).to have_received(:update)
            .with(params: updated_model)
          expect(Argo::Indexer).to have_received(:reindex_pid_remotely).with(pid)
        end
      end
    end
  end
end
