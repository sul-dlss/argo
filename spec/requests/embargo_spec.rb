# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Set embargo for an object' do
  before do
    allow(Dor::Services::Client).to receive(:object).with(pid).and_return(object_service)
  end

  let(:user) { create(:user) }
  let(:object_service) { instance_double(Dor::Services::Client::Object, find: cocina) }

  describe '#update' do
    let(:pid) { 'druid:bc123df4567' }
    let(:cocina) do
      Cocina::Models.build({
                             'label' => 'My ETD',
                             'version' => 1,
                             'type' => Cocina::Models::Vocab.object,
                             'externalIdentifier' => pid,
                             'access' => {
                               'access' => 'stanford',
                               'download' => 'stanford',
                               'embargo' => {
                                 'releaseDate' => '2040-05-05',
                                 'access' => 'world',
                                 'download' => 'world'
                               }
                             },
                             'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
                             'structural' => {},
                             'identification' => {}
                           })
    end
    let(:object_service) { instance_double(Dor::Services::Client::Object, find: cocina, update: true) }

    context "when they don't have manage access" do
      before do
        sign_in user
      end

      it 'returns 403' do
        patch "/items/#{pid}/embargo", params: { embargo_date: '2100-01-01' }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when they have manage access' do
      before do
        sign_in user, groups: ['sdr:administrator-role']
      end

      it 'calls Dor::Services::Client::Embargo#update' do
        patch "/items/#{pid}/embargo", params: { embargo_date: '2100-01-01' }
        expect(response).to have_http_status(:found) # redirect to catalog page
        expect(object_service).to have_received(:update)
      end

      it 'requires a date' do
        expect { patch "/items/#{pid}/embargo", params: {} }.to raise_error(ArgumentError)
      end

      context 'when the date is malformed' do
        it 'shows the error' do
          patch "/items/#{pid}/embargo", params: { embargo_date: 'not-a-date' }
          expect(flash[:error]).to eq 'Invalid date'
        end
      end
    end
  end
end
