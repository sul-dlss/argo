# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Upload the structural CSV' do
  include Dry::Monads[:result]

  let(:user) { create(:user) }
  let(:druid) { 'druid:bc123df4567' }
  let(:state_service) { instance_double(StateService) }

  before do
    allow(Repository).to receive(:find).and_return(cocina_model)
    allow(Repository).to receive(:store)

    allow(StateService).to receive(:new).and_return(state_service, allows_modification?: modifiable)
    allow(Argo::Indexer).to receive(:reindex_druid_remotely)
  end

  context 'when they have manage access' do
    before do
      allow(state_service).to receive(:allows_modification?).and_return(modifiable)

      sign_in user, groups: ['sdr:administrator-role']
    end

    let(:cocina_model) { build(:dro) }
    let(:file) { fixture_file_upload('structure-upload.csv') }

    context 'when object is unlocked' do
      let(:modifiable) { true }

      context 'when valid' do
        before do
          allow(StructureUpdater).to receive(:from_csv).and_return(result)
        end

        let(:result) { Success(cocina_model.structural) }

        context 'when successfully saved' do
          it 'updates the structure' do
            put "/items/#{druid}/structure", params: { csv: file }
            expect(Repository).to have_received(:store)
            expect(response).to have_http_status(:see_other)
          end
        end

        context 'when save failed' do
          before do
            allow(Repository).to receive(:store).and_raise(Dor::Services::Client::UnexpectedResponse)
          end

          it 'updates the structure' do
            put "/items/#{druid}/structure", params: { csv: file }
            expect(response).to have_http_status(:see_other)
            expect(flash[:error]).to match 'unexpected response from dor-services-app'
          end
        end
      end

      context 'when the data is invalid' do
        let(:cocina_model) do
          build(:dro).new(structural: {
                            contains: [
                              {
                                externalIdentifier: 'fs1',
                                label: 'foo',
                                version: 1,
                                type: Cocina::Models::FileSetType.image,
                                structural: {
                                  contains: [
                                    {
                                      externalIdentifier: 'file1',
                                      label: 'foo',
                                      version: 1,
                                      type: Cocina::Models::ObjectType.file,
                                      filename: 'chocolate_cake.jpg'
                                    }
                                  ]
                                }
                              }
                            ]
                          })
        end

        it 'shows an error' do
          put "/items/#{druid}/structure", params: { csv: file }
          expect(Repository).not_to have_received(:store)
          expect(response).to have_http_status(:see_other)
        end
      end
    end

    context 'when object is locked' do
      let(:modifiable) { false }

      it 'updates the structure' do
        put "/items/#{druid}/structure", params: { csv: file }
        expect(Repository).not_to have_received(:store)
        expect(response).to have_http_status(:found)
      end
    end
  end
end
