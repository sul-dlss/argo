# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Set embargo for an object' do
  before do
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_service)
  end

  let(:user) { create(:user) }
  let(:object_service) { instance_double(Dor::Services::Client::Object, find: cocina) }
  let(:druid) { 'druid:bc123df4567' }
  let(:cocina) do
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
                             'view' => 'stanford',
                             'download' => 'stanford',
                             'embargo' => {
                               'releaseDate' => '2040-05-05',
                               'view' => 'world',
                               'download' => 'world'
                             }
                           },
                           'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
                           'structural' => {},
                           identification: { sourceId: 'sul:1234' }
                         })
  end

  describe '#update' do
    let(:object_service) { instance_double(Dor::Services::Client::Object, find: cocina, update: true) }

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
        allow(Argo::Indexer).to receive(:reindex_druid_remotely)
      end

      it 'calls Dor::Services::Client::Embargo#update' do
        patch "/items/#{druid}/embargo", params: { embargo: { release_date: '2100-01-01' } }
        expect(response).to have_http_status(:found) # redirect to catalog page
        expect(object_service).to have_received(:update)
        expect(Argo::Indexer).to have_received(:reindex_druid_remotely)
      end

      it 'requires a date' do
        expect { patch "/items/#{druid}/embargo", params: {} }.to raise_error(ActionController::ParameterMissing)
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
