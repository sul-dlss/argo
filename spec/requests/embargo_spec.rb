# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Set embargo for an object' do
  before do
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_service)
  end

  let(:user) { create(:user) }
  let(:object_service) { instance_double(Dor::Services::Client::Object, find: cocina, reindex: true) }
  let(:druid) { 'druid:bc123df4567' }
  let(:cocina) do
    build(:dro_with_metadata, id: druid).new(access: {
                                               'view' => 'stanford',
                                               'download' => 'stanford',
                                               'embargo' => {
                                                 'releaseDate' => '2040-05-05',
                                                 'view' => 'world',
                                                 'download' => 'world'
                                               }
                                             })
  end

  describe '#update' do
    let(:object_service) { instance_double(Dor::Services::Client::Object, find: cocina, update: true, reindex: true) }

    context "when they don't have manage access" do
      before do
        sign_in user
      end

      it 'returns 403' do
        patch "/items/#{druid}/embargo", params: { embargo: { release_date: '2100-01-01' } }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when they have manage access' do
      before do
        sign_in user, groups: ['sdr:administrator-role']
      end

      it 'calls Dor::Services::Client::Embargo#update' do
        patch "/items/#{druid}/embargo", params: { embargo: { release_date: '2100-01-01' } }
        expect(response).to have_http_status(:found) # redirect to catalog page
        expect(object_service).to have_received(:update)
        expect(object_service).to have_received(:reindex)
      end

      it 'requires a date' do
        patch "/items/#{druid}/embargo", params: {}
        expect(response).to have_http_status(:bad_request)
      end

      context 'when the date is malformed' do
        it 'shows the error' do
          patch "/items/#{druid}/embargo", params: { embargo: { release_date: 'not-a-date' } }
          expect(flash[:error]).to eq 'Invalid date'
        end
      end
    end
  end

  describe '#edit' do
    let(:object_service) { instance_double(Dor::Services::Client::Object, find: cocina) }

    context "when they don't have manage access" do
      before do
        sign_in user
      end

      it 'returns 403' do
        get "/items/#{druid}/embargo/edit"
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when they have manage access' do
      before do
        sign_in user, groups: ['sdr:administrator-role']
      end

      let(:rendered) do
        Capybara::Node::Simple.new(response.body)
      end

      it 'renders the form' do
        get "/items/#{druid}/embargo/edit"
        expect(response).to have_http_status(:ok)
        expect(rendered).to have_css 'form label', text: 'Enter the date when this embargo ends'
        expect(rendered)
          .to have_css 'input.btn.btn-primary[value="Save"]'
      end
    end
  end

  describe '#new' do
    let(:object_service) { instance_double(Dor::Services::Client::Object, find: cocina) }

    context "when they don't have manage access" do
      before do
        sign_in user
      end

      it 'returns 403' do
        get "/items/#{druid}/embargo/new"
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when they have manage access' do
      before do
        sign_in user, groups: ['sdr:administrator-role']
      end

      let(:rendered) do
        Capybara::Node::Simple.new(response.body)
      end

      it 'renders the form' do
        get "/items/#{druid}/embargo/new"

        expect(response).to have_http_status(:ok)
        expect(rendered).to have_css 'form label', text: 'Enter the date when this embargo ends'
        expect(rendered)
          .to have_css 'input.btn.btn-primary[value="Save"]'
      end
    end
  end
end
