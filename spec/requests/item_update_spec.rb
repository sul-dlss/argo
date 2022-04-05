# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Set the properties for an item' do
  let(:user) { create(:user) }
  let(:druid) { 'druid:bc123df4567' }
  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model, update: true) }

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    allow(Argo::Indexer).to receive(:reindex_druid_remotely)
  end

  context 'when they have manage access' do
    before do
      sign_in user, groups: ['sdr:administrator-role']
    end

    let(:existing_access) { {} }
    let(:existing_structural) { {} }
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
                             'access' => existing_access,
                             'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
                             'structural' => existing_structural,
                             identification: { sourceId: 'sul:1234' }
                           })
    end

    context 'when barcode is passed' do
      let(:updated_model) do
        cocina_model.new(
          {
            identification: {
              barcode: '36105010362304',
              sourceId: 'sul:1234'
            }
          }
        )
      end

      it 'sets the new barcode' do
        patch "/items/#{druid}", params: { item: { barcode: '36105010362304' } }

        expect(object_client).to have_received(:update)
          .with(params: updated_model)
        expect(Argo::Indexer).to have_received(:reindex_druid_remotely)
        expect(response.code).to eq('303')
      end
    end

    context 'when copyright is passed' do
      let(:updated_model) do
        cocina_model.new(
          {
            'access' => {
              'copyright' => 'in public domain'
            }
          }
        )
      end

      it 'sets the new copyright' do
        patch "/items/#{druid}", params: { item: { copyright: 'in public domain' } }

        expect(object_client).to have_received(:update)
          .with(params: updated_model)
        expect(Argo::Indexer).to have_received(:reindex_druid_remotely)
        expect(response.code).to eq('303')
      end
    end

    context 'when use_statement is passed' do
      let(:updated_model) do
        cocina_model.new(
          {
            'access' => {
              'useAndReproductionStatement' => 'call before using'
            }
          }
        )
      end

      it 'sets the new use and reproduction statement' do
        patch "/items/#{druid}", params: { item: { use_statement: 'call before using' } }

        expect(object_client).to have_received(:update)
          .with(params: updated_model)
        expect(Argo::Indexer).to have_received(:reindex_druid_remotely)
        expect(response.code).to eq('303')
      end
    end

    context 'when license is passed' do
      let(:updated_model) do
        cocina_model.new(
          {
            'access' => {
              'license' => 'https://creativecommons.org/licenses/by/4.0/legalcode'
            }
          }
        )
      end

      it 'sets the new license statement' do
        patch "/items/#{druid}", params: { item: { license: 'https://creativecommons.org/licenses/by/4.0/legalcode' } }

        expect(object_client).to have_received(:update)
          .with(params: updated_model)
        expect(Argo::Indexer).to have_received(:reindex_druid_remotely)
        expect(response.code).to eq('303')
      end
    end

    describe 'access rights' do
      let(:existing_structural) do
        {
          contains: [
            {
              externalIdentifier: 'fileset_1',
              type: Cocina::Models::FileSetType.file,
              version: 1,
              label: 'Fileset 1',
              structural: {
                contains: [
                  {
                    externalIdentifier: 'file_1',
                    type: Cocina::Models::ObjectType.file,
                    version: 1,
                    access: existing_file_access,
                    administrative: {
                      publish: true,
                      sdrPreserve: true,
                      shelve: true
                    },
                    filename: 'fred',
                    hasMessageDigests: [],
                    label: 'hi'
                  }
                ]
              }
            }
          ],
          isMemberOf: ['druid:sx469gx8472'] # to ensure this is not modified
        }
      end

      let(:existing_file_access) do
        {
          view: 'world',
          download: 'world'
        }
      end

      context 'when they are location access' do
        let(:updated_model) do
          cocina_model.new(
            {
              access: {
                view: 'world',
                download: 'location-based',
                location: 'm&m',
                controlledDigitalLending: false
              },
              structural: {
                contains: [
                  {
                    externalIdentifier: 'fileset_1',
                    type: Cocina::Models::FileSetType.file,
                    version: 1,
                    label: 'Fileset 1',
                    structural: {
                      contains: [
                        {
                          externalIdentifier: 'file_1',
                          type: Cocina::Models::ObjectType.file,
                          version: 1,
                          access: {
                            view: 'world',
                            download: 'location-based',
                            location: 'm&m',
                            controlledDigitalLending: false
                          },
                          administrative: {
                            publish: true,
                            sdrPreserve: true,
                            shelve: true
                          },
                          filename: 'fred',
                          hasMessageDigests: [],
                          label: 'hi'
                        }
                      ]
                    }
                  }
                ],
                isMemberOf: ['druid:sx469gx8472'] # to ensure this is not modified
              }
            }
          )
        end

        it 'sets the new access rights (without overwriting collection)' do
          patch "/items/#{druid}", params: {
            item: {
              view_access: 'world',
              download_access: 'location-based',
              access_location: 'm&m',
              controlled_digital_lending: '0'
            }
          }

          expect(object_client).to have_received(:update)
            .with(params: updated_model)
          expect(Argo::Indexer).to have_received(:reindex_druid_remotely)
          expect(response.code).to eq('303')
        end
      end

      context 'when changing from location access' do
        let(:existing_access) do
          {
            view: 'world',
            download: 'location-based',
            location: 'm&m',
            controlledDigitalLending: false
          }
        end

        # This allows us to test that the access on the file was changed as well.
        let(:existing_file_access) do
          existing_access
        end

        let(:updated_model) do
          cocina_model.new(
            {
              access: {
                view: 'stanford',
                download: 'stanford',
                location: nil,
                controlledDigitalLending: false
              },
              structural: {
                contains: [
                  {
                    externalIdentifier: 'fileset_1',
                    type: Cocina::Models::FileSetType.file,
                    version: 1,
                    label: 'Fileset 1',
                    structural: {
                      contains: [
                        {
                          externalIdentifier: 'file_1',
                          type: Cocina::Models::ObjectType.file,
                          version: 1,
                          access: {
                            view: 'stanford',
                            download: 'stanford',
                            location: nil,
                            controlledDigitalLending: false
                          },
                          administrative: {
                            publish: true,
                            sdrPreserve: true,
                            shelve: true
                          },
                          filename: 'fred',
                          hasMessageDigests: [],
                          label: 'hi'
                        }
                      ]
                    }
                  }
                ],
                isMemberOf: ['druid:sx469gx8472'] # to ensure this is not modified
              }
            }
          )
        end

        it 'sets the new access rights' do
          patch "/items/#{druid}", params: {
            item: {
              view_access: 'stanford',
              download_access: 'stanford',
              controlled_digital_lending: '0'
            }
          }

          expect(object_client).to have_received(:update)
            .with(params: updated_model)
          expect(Argo::Indexer).to have_received(:reindex_druid_remotely)
          expect(response.code).to eq('303')
        end
      end

      context 'when changing to dark access' do
        let(:existing_access) do
          {
            view: 'world',
            download: 'location-based',
            location: 'm&m',
            controlledDigitalLending: false
          }
        end

        # This allows us to test that the access on the file was changed as well.
        let(:existing_file_access) do
          existing_access
        end

        let(:updated_model) do
          cocina_model.new(
            {
              access: {
                view: 'dark',
                download: 'none',
                location: nil,
                controlledDigitalLending: false
              },
              structural: {
                contains: [
                  {
                    externalIdentifier: 'fileset_1',
                    type: Cocina::Models::FileSetType.file,
                    version: 1,
                    label: 'Fileset 1',
                    structural: {
                      contains: [
                        {
                          externalIdentifier: 'file_1',
                          type: Cocina::Models::ObjectType.file,
                          version: 1,
                          access: {
                            view: 'dark',
                            download: 'none',
                            location: nil,
                            controlledDigitalLending: false
                          },
                          administrative: {
                            publish: false,
                            sdrPreserve: true,
                            shelve: false
                          },
                          filename: 'fred',
                          hasMessageDigests: [],
                          label: 'hi'
                        }
                      ]
                    }
                  }
                ],
                isMemberOf: ['druid:sx469gx8472'] # to ensure this is not modified
              }
            }
          )
        end

        it 'sets the new access rights' do
          patch "/items/#{druid}", params: {
            item: {
              view_access: 'dark',
              controlled_digital_lending: '0'
            }
          }

          expect(object_client).to have_received(:update)
            .with(params: updated_model)
          expect(Argo::Indexer).to have_received(:reindex_druid_remotely)
          expect(response.code).to eq('303')
        end
      end

      context 'when they are CDL access' do
        let(:updated_model) do
          cocina_model.new(
            {
              access: {
                view: 'stanford',
                download: 'none',
                controlledDigitalLending: true
              },
              structural: {
                contains: [
                  {
                    externalIdentifier: 'fileset_1',
                    type: Cocina::Models::FileSetType.file,
                    version: 1,
                    label: 'Fileset 1',
                    structural: {
                      contains: [
                        {
                          externalIdentifier: 'file_1',
                          type: Cocina::Models::ObjectType.file,
                          version: 1,
                          access: {
                            view: 'stanford',
                            download: 'none',
                            location: nil,
                            controlledDigitalLending: true
                          },
                          administrative: {
                            publish: true,
                            sdrPreserve: true,
                            shelve: true
                          },
                          filename: 'fred',
                          hasMessageDigests: [],
                          label: 'hi'
                        }
                      ]
                    }
                  }
                ],
                isMemberOf: ['druid:sx469gx8472'] # to ensure this is not modified
              }
            }
          )
        end

        it 'sets the new access rights' do
          patch "/items/#{druid}", params: {
            item: {
              view_access: 'stanford',
              download_access: 'none',
              controlled_digital_lending: '1'
            }
          }

          expect(object_client).to have_received(:update)
            .with(params: updated_model)
          expect(Argo::Indexer).to have_received(:reindex_druid_remotely)
          expect(response.code).to eq('303')
        end
      end
    end

    context 'when there is an error building the Cocina' do
      it 'draws the error' do
        patch "/items/#{druid}", params: { item: { barcode: 'invalid' } }, headers: { 'Turbo-Frame' => 'barcode' }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include '<turbo-frame id="barcode">Error building Cocina: &quot;invalid&quot; isn&#39;t one of in #/components/schemas/Barcode</turbo-frame>'
      end
    end

    context 'when there is an error retrieving the Cocina' do
      it 'draws the error' do
        allow(object_client).to receive(:update).and_raise(Dor::Services::Client::BadRequestError, '({"errors":[{"detail":"broken"}]})')
        patch "/items/#{druid}", params: { item: { barcode: '36105010362304' } }, headers: { 'Turbo-Frame' => 'barcode' }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include '<turbo-frame id="barcode">Unable to retrieve the cocina model: broken</turbo-frame>'
      end
    end
  end
end
