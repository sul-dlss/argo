# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CatalogController, type: :controller do
  let(:druid) { 'druid:pv820dk6668' } # a fixture Dor::Item record
  let(:user) { create(:user) }

  describe '#index' do
    let(:search_service) { instance_double(Blacklight::SearchService, search_results: []) }

    before do
      expect(controller).to receive(:search_service).and_return(search_service)
      sign_in user
    end

    it 'is succesful' do
      get :index
      expect(response).to be_successful
      expect(assigns[:presenter]).to be_a HomeTextPresenter
    end
  end

  describe '#show' do
    before do
      ActiveFedora::SolrService.add(id: druid,
                                    sw_display_title_tesim: 'Slides, IA 11, Geodesic Domes, Double Skin "Growth" House, N.C. State, 1953')
      ActiveFedora::SolrService.commit
      item = instantiate_fixture(druid, Dor::Item)
      allow(Dor).to receive(:find).with(druid).and_return(item)
    end

    context 'without logging in' do
      it 'redirects to login' do
        get 'show', params: { id: druid }
        expect(response).to redirect_to new_user_session_path
      end
    end

    describe 'with user' do
      before do
        sign_in user
      end

      context 'when unauthorized' do
        before do
          allow(controller).to receive(:authorize!).with(:view_metadata, Dor::Item).and_raise(CanCan::AccessDenied)
        end

        it 'is forbidden' do
          get 'show', params: { id: druid }
          expect(response).to be_forbidden
        end
      end

      context 'when authorized' do
        before do
          allow(controller).to receive(:authorize!).with(:view_metadata, Dor::Item)
          allow(Dor::Services::Client).to receive(:object).and_return(object_client)
        end

        let(:events_client) { instance_double(Dor::Services::Client::Events, list: []) }
        let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model, events: events_client) }
        let(:cocina_model) { instance_double(Cocina::Models::DRO, administrative: administrative) }
        let(:administrative) { instance_double(Cocina::Models::Administrative, releaseTags: []) }

        it 'is successful' do
          get 'show', params: { id: druid }
          expect(response).to be_successful
        end
      end
    end
  end

  describe 'blacklight config' do
    let(:config) { controller.blacklight_config }

    it 'has the date facets' do
      keys = config.facet_fields.keys
      expect(keys).to include 'registered_date', SolrDocument::FIELD_REGISTERED_DATE.to_s
      expect(keys).to include 'accessioned_latest_date', SolrDocument::FIELD_LAST_ACCESSIONED_DATE.to_s
      expect(keys).to include 'published_latest_date', SolrDocument::FIELD_LAST_PUBLISHED_DATE.to_s
      expect(keys).to include 'submitted_latest_date', SolrDocument::FIELD_LAST_SUBMITTED_DATE.to_s
      expect(keys).to include 'deposited_date', SolrDocument::FIELD_LAST_DEPOSITED_DATE.to_s
      expect(keys).to include 'object_modified_date', SolrDocument::FIELD_LAST_MODIFIED_DATE.to_s
      expect(keys).to include 'version_opened_date', SolrDocument::FIELD_LAST_OPENED_DATE.to_s
      expect(keys).to include 'embargo_release_date', SolrDocument::FIELD_EMBARGO_RELEASE_DATE.to_s
    end
    it 'does not show raw date field facets' do
      raw_fields = [
        SolrDocument::FIELD_REGISTERED_DATE,
        SolrDocument::FIELD_LAST_ACCESSIONED_DATE,
        SolrDocument::FIELD_LAST_PUBLISHED_DATE,
        SolrDocument::FIELD_LAST_SUBMITTED_DATE,
        SolrDocument::FIELD_LAST_DEPOSITED_DATE,
        SolrDocument::FIELD_LAST_MODIFIED_DATE,
        SolrDocument::FIELD_LAST_OPENED_DATE,
        SolrDocument::FIELD_EMBARGO_RELEASE_DATE
      ].map(&:to_s)
      config.facet_fields.each do |field|
        expect(field[1].if).to eq false if raw_fields.include?(field[0])
      end
    end
    it 'uses POST as the http method' do
      expect(config.http_method).to eq :post
    end
  end
end
