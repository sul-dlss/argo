# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Set the properties for an item' do
  let(:user) { create(:user) }
  let(:druid) { 'druid:bc123df4567' }
  let(:object_client) { instance_double(Dor::Services::Client::Object, update: true) }

  before do
    allow(Repository).to receive(:find).and_return(cocina_model)
    allow(Argo::Indexer).to receive(:reindex_druid_remotely)
  end

  context 'when they have manage access' do
    before do
      sign_in user, groups: ['sdr:administrator-role']
    end

    let(:cocina_model) { build(:dro_with_metadata) }

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

      before do
        allow(Dor::Services::Client).to receive(:object).and_return(object_client)
      end

      it 'sets the new barcode' do
        patch "/items/#{druid}", params: { item: { barcode: '36105010362304' } }

        expect(object_client).to have_received(:update)
          .with(params: updated_model)
        expect(Argo::Indexer).to have_received(:reindex_druid_remotely)
        expect(response).to have_http_status(:see_other)
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

      before do
        allow(Dor::Services::Client).to receive(:object).and_return(object_client)
      end

      it 'sets the new copyright' do
        patch "/items/#{druid}", params: { item: { copyright: 'in public domain' } }

        expect(object_client).to have_received(:update)
          .with(params: updated_model)
        expect(Argo::Indexer).to have_received(:reindex_druid_remotely)
        expect(response).to have_http_status(:see_other)
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

      before do
        allow(Dor::Services::Client).to receive(:object).and_return(object_client)
      end

      it 'sets the new use and reproduction statement' do
        patch "/items/#{druid}", params: { item: { use_statement: 'call before using' } }

        expect(object_client).to have_received(:update)
          .with(params: updated_model)
        expect(Argo::Indexer).to have_received(:reindex_druid_remotely)
        expect(response).to have_http_status(:see_other)
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

      before do
        allow(Dor::Services::Client).to receive(:object).and_return(object_client)
      end

      it 'sets the new license statement' do
        patch "/items/#{druid}", params: { item: { license: 'https://creativecommons.org/licenses/by/4.0/legalcode' } }

        expect(object_client).to have_received(:update)
          .with(params: updated_model)
        expect(Argo::Indexer).to have_received(:reindex_druid_remotely)
        expect(response).to have_http_status(:see_other)
      end
    end

    describe 'access rights' do
      let(:cocina_model) do
        build(:dro_with_metadata).new(access: existing_access, structural: existing_structural)
      end

      let(:existing_access) { { view: 'world', download: 'none' } }
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
                    administrative: existing_file_administrative,
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
      let(:existing_file_administrative) do
        {
          publish: true,
          sdrPreserve: true,
          shelve: true
        }
      end
      let(:existing_file_access) do
        {
          view: 'world',
          download: 'world'
        }
      end

      before do
        allow(Dor::Services::Client).to receive(:object).and_return(object_client)
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
          expect(response).to have_http_status(:see_other)
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
          expect(response).to have_http_status(:see_other)
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
          expect(response).to have_http_status(:see_other)
        end
      end

      context 'when changing from dark access' do
        let(:existing_access) do
          {
            view: 'dark',
            download: 'none'
          }
        end

        let(:existing_file_administrative) do
          {
            publish: false,
            sdrPreserve: true,
            shelve: false
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
                view: 'location-based',
                download: 'location-based',
                location: 'spec',
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
                            view: 'location-based',
                            download: 'location-based',
                            location: 'spec',
                            controlledDigitalLending: false
                          },
                          administrative: existing_file_administrative, # Nothing was changed
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
              view_access: 'location-based',
              download_access: 'location-based',
              access_location: 'spec',
              controlled_digital_lending: '0'
            }
          }

          expect(object_client).to have_received(:update)
            .with(params: updated_model)
          expect(Argo::Indexer).to have_received(:reindex_druid_remotely)
          expect(response).to have_http_status(:see_other)
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
          expect(response).to have_http_status(:see_other)
        end
      end
    end

    context 'when there is an error building the Cocina' do
      it 'draws the error' do
        patch "/items/#{druid}", params: { item: { barcode: 'invalid' } }, headers: { 'Turbo-Frame' => 'barcode' }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include '<turbo-frame id="barcode">&quot;invalid&quot; is not a valid barcode</turbo-frame>'
      end
    end

    context 'when there is an error saving the Cocina' do
      let(:json_response) do
        <<~JSON
          {"errors":
            [{
              "status":"422",
              "title":"problem",
              "detail":"broken"
            }]
          }
        JSON
      end

      before do
        stub_request(:patch, "#{Settings.dor_services.url}/v1/objects/druid:bc234fg5678")
          .to_return(status: 422, body: json_response, headers: { 'content-type' => 'application/vnd.api+json' })
      end

      it 'draws the error' do
        patch "/items/#{druid}", params: { item: { barcode: '36105010362304' } },
                                 headers: { 'Turbo-Frame' => 'barcode' }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include '<turbo-frame id="barcode">Unable to retrieve the cocina model: broken</turbo-frame>'
      end
    end
  end
end
