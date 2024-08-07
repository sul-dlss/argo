# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Upload the structural CSV' do
  include Dry::Monads[:result]

  let(:user) { create(:user) }
  let(:druid) { cocina_model.externalIdentifier }
  let(:version_service) { instance_double(VersionService, open?: open) }

  before do
    allow(Repository).to receive(:find).and_return(cocina_model)
    allow(VersionService).to receive(:new).and_return(version_service)
  end

  context 'when they have manage access' do
    before do
      sign_in user, groups: ['sdr:administrator-role']
    end

    let(:cocina_model) { build(:dro_with_metadata) }
    let(:file) { fixture_file_upload('structure-upload.csv') }

    context 'when object is unlocked' do
      let(:open) { true }

      context 'when valid' do
        before do
          allow(StructureUpdater).to receive(:from_csv).and_return(result)
        end

        let(:result) { Success(cocina_model.structural) }

        context 'when successfully saved' do
          before do
            allow(Repository).to receive(:store)
          end

          it 'updates the structure' do
            put "/items/#{druid}/structure", params: { csv: file }
            expect(Repository).to have_received(:store)
            expect(response).to have_http_status(:see_other)
            expect(StructureUpdater).to have_received(:from_csv) do |_cocina, csv|
              expect(csv.encoding).to eq Encoding::UTF_8
            end
          end
        end

        context 'when save failed' do
          before do
            stub_request(:patch, "#{Settings.dor_services.url}/v1/objects/#{druid}")
              .to_return(status: 422, body: json_response, headers: { 'content-type' => 'application/vnd.api+json' })
          end

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

          it 'shows a detailed message about what went wrong' do
            put "/items/#{druid}/structure", params: { csv: file }
            expect(response).to have_http_status(:see_other)
            expect(flash[:error]).to match 'broken'
          end
        end
      end

      context 'when the data is invalid' do
        let(:cocina_model) do
          build(:dro_with_metadata).new(structural: {
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

        before do
          allow(Repository).to receive(:store)
        end

        it 'shows an error' do
          put "/items/#{druid}/structure", params: { csv: file }
          expect(Repository).not_to have_received(:store)
          expect(response).to have_http_status(:see_other)
        end
      end
    end

    context 'when object is locked' do
      let(:open) { false }

      before do
        allow(Repository).to receive(:store)
      end

      it 'updates the structure' do
        put "/items/#{druid}/structure", params: { csv: file }
        expect(Repository).not_to have_received(:store)
        expect(response).to have_http_status(:found)
      end
    end
  end
end
