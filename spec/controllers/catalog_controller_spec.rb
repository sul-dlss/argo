# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CatalogController, type: :controller do
  before do
    @druid = 'rn653dy9317' # a fixture Dor::Item record
    @item = instantiate_fixture(@druid, Dor::Item)
  end

  let(:user) { create(:user) }

  describe '#index' do
    before do
      expect(controller).to receive(:search_results).and_return([])
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
      allow(Dor).to receive(:find).with("druid:#{@druid}").and_return(@item)
    end

    context 'without logging in' do
      it 'redirects to login' do
        get 'show', params: { id: @druid }
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
          get 'show', params: { id: @druid }
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
          get 'show', params: { id: @druid }
          expect(response).to be_successful
        end
      end

      context 'when not found' do
        before do
          allow(Dor).to receive(:find).with(druid).and_raise(ActiveFedora::ObjectNotFoundError)
        end

        let(:druid) { 'druid:zz999zz9999' }

        it 'returns not found' do
          get 'show', params: { id: druid }
          expect(response).to be_not_found
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
        expect(field[1].show).to be_falsey if raw_fields.include?(field[0])
      end
    end
    it 'uses POST as the http method' do
      expect(config.http_method).to eq :post
    end
  end

  describe '#manage_release' do
    before do
      allow(Dor).to receive(:find).with("druid:#{@druid}").and_return(@item)
      sign_in user
    end

    context 'for content managers' do
      before do
        allow(controller).to receive(:authorize!).with(:manage_item, Dor::Item).and_return(true)
        allow(controller).to receive(:fetch).with("druid:#{@druid}").and_return(double)
      end

      it 'authorizes the view' do
        get :manage_release, params: { id: "druid:#{@druid}" }
        expect(response).to have_http_status(:success)
      end
    end

    context 'for unauthorized_user' do
      it 'returns forbidden' do
        get :manage_release, params: { id: "druid:#{@druid}" }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
