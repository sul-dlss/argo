require 'spec_helper'

RSpec.describe CatalogController, type: :controller do
  before do
    @druid = 'rn653dy9317' # a fixture Dor::Item record
    @item = instantiate_fixture(@druid, Dor::Item)
  end

  let(:user) { create(:user) }

  describe '#index' do
    before do
      allow(user).to receive(:permitted_apos).and_return([])
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
        expect(response.code).to eq('401') # Unauthorized without webauth, no place to redirect
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
        end
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
    it 'should have the date facets' do
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
    it 'should not show raw date field facets' do
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
    it 'should use POST as the http method' do
      expect(config.http_method).to eq :post
    end
  end

  describe '#load_bulk_jobs' do
    let(:sorted_bulk_job_info) { controller.send(:load_bulk_jobs, 'druid:bc682xk5613') }
    it 'should load the expected number of records' do
      expect(sorted_bulk_job_info.length).to eq 5
    end
    it 'should load an empty record for a job with a missing log file (and the record should sort to the end)' do
      expect(sorted_bulk_job_info.last).to be_empty
    end
    it 'should load the expected information when a log file is present' do
      # spot check a couple known records
      expect(sorted_bulk_job_info[3]).to include(
        'argo.bulk_metadata.bulk_log_job_start' => '2016-04-21 09:57am',
        'argo.bulk_metadata.bulk_log_user' => 'tommyi',
        'argo.bulk_metadata.bulk_log_input_file' => 'crowdsourcing_bridget_1.xlsx',
        'argo.bulk_metadata.bulk_log_xml_timestamp' => '2016-04-21 09:57am',
        'argo.bulk_metadata.bulk_log_xml_filename' => 'crowdsourcing_bridget_1-MODS.xml',
        'argo.bulk_metadata.bulk_log_record_count' => '20',
        'argo.bulk_metadata.bulk_log_job_complete' => '2016-04-21 09:57am',
        'dir' => 'druid:bc682xk5613/2016_04_21_16_56_40_824',
        'argo.bulk_metadata.bulk_log_druids_loaded' => 0
      )
      expect(sorted_bulk_job_info[0]).to include(
        'argo.bulk_metadata.bulk_log_job_start' => '2016-04-21 10:34am',
        'argo.bulk_metadata.bulk_log_user' => 'tommyi',
        'argo.bulk_metadata.bulk_log_input_file' => 'crowdsourcing_bridget_1.xlsx',
        'argo.bulk_metadata.bulk_log_note' => 'convertonly',
        'argo.bulk_metadata.bulk_log_internal_error' => 'the server responded with status 500',
        'error' => 1,
        'argo.bulk_metadata.bulk_log_empty_response' => 'ERROR: No response from https://modsulator-app-stage.stanford.edu/v1/modsulator',
        'argo.bulk_metadata.bulk_log_error_exception' => 'Got no response from server',
        'argo.bulk_metadata.bulk_log_job_complete' => '2016-04-21 10:34am',
        'dir' => 'druid:bc682xk5613/2016_04_21_17_34_02_445',
        'argo.bulk_metadata.bulk_log_druids_loaded' => 0
      )
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
