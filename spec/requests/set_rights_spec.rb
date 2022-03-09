# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Set rights for an object' do
  context 'when they have manage access' do
    let(:user) { create(:user) }
    let(:pid) { 'druid:cc243mg0841' }
    let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model, update: true) }

    before do
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
      allow(Argo::Indexer).to receive(:reindex_pid_remotely)
      sign_in user, groups: ['sdr:administrator-role']
    end

    context 'for a DRO' do
      let(:cocina_model) do
        Cocina::Models.build({
                               'label' => 'My ETD',
                               'version' => 1,
                               'type' => Cocina::Models::ObjectType.object,
                               'externalIdentifier' => pid,
                               'description' => {
                                 'title' => [{ 'value' => 'My ETD' }],
                                 'purl' => "https://purl.stanford.edu/#{pid.delete_prefix('druid:')}"
                               },
                               'access' => {
                                 'view' => 'world',
                                 'download' => 'world',
                                 embargo: {
                                   releaseDate: '2021-02-11T00:00:00.000+00:00',
                                   view: 'world',
                                   download: 'world'
                                 }
                               },
                               'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
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
                                           'access' => { view: 'world', download: 'world' },
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

      context 'when setting dark access' do
        let(:updated_model) do
          cocina_model.new(
            {
              'access' => {
                'view' => 'dark',
                'download' => 'none',
                'location' => nil,
                'controlledDigitalLending' => false,
                embargo: {
                  releaseDate: '2021-02-11T00:00:00.000+00:00',
                  view: 'world',
                  download: 'world'
                }
              },
              'structural' => {
                'contains' => [
                  {
                    'externalIdentifier' => 'cc243mg0841_1',
                    'label' => 'Fileset 1',
                    'type' => Cocina::Models::FileSetType.file,
                    'version' => 1,
                    'structural' => {
                      'contains' => [
                        {
                          'externalIdentifier' => 'cc243mg0841_1',
                          'label' => 'Page 1',
                          'type' => Cocina::Models::ObjectType.file,
                          'version' => 1,
                          'access' => { view: 'dark', download: 'none', location: nil, controlledDigitalLending: false },
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
                'view' => 'stanford',
                'download' => 'stanford',
                'location' => nil,
                'controlledDigitalLending' => false,
                'embargo' => {
                  'releaseDate' => '2021-02-11T00:00:00.000+00:00',
                  'view' => 'world',
                  'download' => 'world'
                }
              },
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
                          'access' => {
                            'view' => 'stanford',
                            'download' => 'stanford',
                            'location' => nil,
                            'controlledDigitalLending' => false
                          },
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
                'view' => 'stanford',
                'download' => 'none',
                'location' => nil,
                'controlledDigitalLending' => true,
                'embargo' => {
                  'releaseDate' => '2021-02-11T00:00:00.000+00:00',
                  'view' => 'world',
                  'download' => 'world'
                }
              },
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
                          'access' => {
                            'view' => 'stanford',
                            'download' => 'none',
                            'location' => nil,
                            'controlledDigitalLending' => true
                          },
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
                                 'type' => Cocina::Models::ObjectType.object,
                                 'externalIdentifier' => pid,
                                 'description' => {
                                   'title' => [{ 'value' => 'My ETD' }],
                                   'purl' => "https://purl.stanford.edu/#{pid.delete_prefix('druid:')}"
                                 },
                                 'access' => {
                                   'view' => 'stanford',
                                   'download' => 'none',
                                   'controlledDigitalLending' => true,
                                   'embargo' => {
                                     releaseDate: '2021-02-11T00:00:00.000+00:00',
                                     view: 'world',
                                     download: 'world'
                                   }
                                 },
                                 'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
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
                                             'access' => {
                                               'view' => 'world',
                                               'download' => 'world',
                                               'location' => nil,
                                               'controlledDigitalLending' => false
                                             },
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

        let(:updated_model) do
          cocina_model.new(
            {
              'access' => {
                'view' => 'world',
                'download' => 'world',
                'location' => nil,
                'controlledDigitalLending' => false,
                'embargo' => {
                  'releaseDate' => '2021-02-11T00:00:00.000+00:00',
                  'view' => 'world',
                  'download' => 'world'
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

      context 'when setting citation-only access' do
        let(:updated_model) do
          cocina_model.new(
            {
              'access' => {
                'view' => 'citation-only',
                'download' => 'none',
                'location' => nil,
                'controlledDigitalLending' => false,
                'embargo' => {
                  'releaseDate' => '2021-02-11T00:00:00.000+00:00',
                  'view' => 'world',
                  'download' => 'world'
                }
              },
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
                          'access' => {
                            'view' => 'dark',
                            'download' => 'none',
                            'location' => nil,
                            'controlledDigitalLending' => false
                          },
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
              }
            }
          )
        end

        it 'sets the access' do
          post "/items/#{pid}/set_rights", params: { dro_rights_form: { rights: 'citation-only' } }
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
                               'type' => Cocina::Models::ObjectType.collection,
                               'externalIdentifier' => pid,
                               'description' => {
                                 'title' => [{ 'value' => 'My ETD' }],
                                 'purl' => "https://purl.stanford.edu/#{pid.delete_prefix('druid:')}"
                               },
                               'access' => {
                                 'view' => 'world'
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
                'view' => 'dark'
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

      context 'when a bulk request' do
        let(:updated_model) do
          cocina_model.new(
            {
              'access' => {
                'view' => 'dark'
              }
            }
          )
        end

        it 'sets the access' do
          post "/items/#{pid}/set_rights", params: { bulk: true, dro_rights_form: { rights: 'dark' } }
          expect(response).to have_http_status(:ok)
          expect(object_client).to have_received(:update)
            .with(params: updated_model)
          expect(Argo::Indexer).to have_received(:reindex_pid_remotely).with(pid)
        end
      end
    end

    context "when the cocina model isn't found" do
      let(:cocina_model) do
        Cocina::Models.build({
                               'label' => 'My ETD',
                               'version' => 1,
                               'type' => Cocina::Models::ObjectType.collection,
                               'externalIdentifier' => pid,
                               'description' => {
                                 'title' => [{ 'value' => 'My ETD' }],
                                 'purl' => "https://purl.stanford.edu/#{pid.delete_prefix('druid:')}"
                               },
                               'access' => {
                                 'view' => 'world'
                               },
                               'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
                               'identification' => {}
                             })
      end
      let(:metadata_client) { instance_double(Dor::Services::Client::Metadata, datastreams: []) }
      let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, inventory: []) }
      let(:object_client) do
        instance_double(Dor::Services::Client::Object,
                        find: cocina_model,
                        events: events_client,
                        metadata: metadata_client,
                        version: version_client)
      end
      let(:events_client) { instance_double(Dor::Services::Client::Events, list: []) }
      let(:service) { instance_double(Blacklight::SearchService, fetch: [nil, doc]) }
      let(:doc) { SolrDocument.new id: pid, SolrDocument::FIELD_OBJECT_TYPE => 'item' }
      let(:error) do
        '{"errors":[{"status":"422","title":"Unexpected Cocina::Mapper.build error",' \
        '"detail":"#/components/schemas/SourceId pattern ^.+:.+$ does not match value: bad_source_id:, ' \
        'example: sul:PC0170_s3_Fiesta_Bowl_2012-01-02_210609_2026"}]}'
      end

      before do
        allow(Blacklight::SearchService).to receive(:new).and_return(service)
        allow(object_client).to receive(:find).and_raise(Dor::Services::Client::UnexpectedResponse, "Error (#{error})")
        allow(version_client).to receive(:current).and_return(1)
      end

      it 'redirects to the show page with an error' do
        post "/items/#{pid}/set_rights", params: { dro_rights_form: { rights: 'dark' } }
        expect(response).to redirect_to(solr_document_path(pid))
        follow_redirect!
        expect(response.body).to include 'Unable to retrieve the cocina model'
      end
    end
  end
end
