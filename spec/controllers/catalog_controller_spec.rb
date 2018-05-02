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

  shared_examples 'APO-independent auth' do
    before do
      allow(Dor).to receive(:find).with("druid:#{@druid}").and_return(@item)
    end
    describe 'no user' do
      let(:user) { nil }
      it 'basic get redirects to login' do
        get 'show', params: { :id => @druid }
        expect(response.code).to eq('401') # Unauthorized without webauth, no place to redirect
      end
    end

    describe 'with user' do
      before do
        sign_in user
      end
      it 'unauthorized_user' do
        get 'show', params: { :id => @druid }
        expect(response.code).to eq('403') # two different flavors
        # expect(response.body).to include 'No APO'
      end
      it 'is_admin?' do
        allow(user).to receive(:is_admin?).and_return(true)
        get 'show', params: { :id => @druid }
        expect(response.code).to eq('200')
      end
      it 'is_viewer?' do
        allow(user).to receive(:is_viewer?).and_return(true)
        get 'show', params: { :id => @druid }
        expect(response.code).to eq('200')
      end
      it 'impersonating nobody' do
        user.set_groups_to_impersonate(['some:irrelevance'])
        get 'show', params: { :id => @druid }
        expect(response.code).to eq('403')
      end
      it 'impersonating viewer' do
        user.set_groups_to_impersonate(['some:irrelevance', 'workgroup:sdr:viewer-role'])
        get 'show', params: { :id => @druid }
        expect(response.code).to eq('200')
      end
      it 'impersonating admin' do
        user.set_groups_to_impersonate(['some:irrelevance', 'workgroup:sdr:administrator-role'])
        get 'show', params: { :id => @druid }
        expect(response.code).to eq('200')
      end
    end
  end

  describe '#show enforces permissions' do
    before do
      allow(Dor).to receive(:find).with("druid:#{@druid}").and_return(@item)
      sign_in user
    end
    describe 'without APO' do
      before do
        allow(@item).to receive(:admin_policy_object).and_return(nil)
      end

      describe 'impersonating user with no extra powers' do
        it 'is forbidden since there is no APO' do
          get 'show', params: { :id => @druid }
          expect(response.code).to eq('403')  # Forbidden
        end
      end
      it_behaves_like 'APO-independent auth'
    end

    describe 'with APO' do
      before do
        @apo_druid = 'druid:hv992ry2431'
        @apo = instantiate_fixture('hv992ry2431', Dor::AdminPolicyObject)
        allow(@item).to receive(:admin_policy_object).and_return(@apo)
        allow(user).to receive(:roles).with(@apo_druid).and_return([]) if user
      end
      describe 'impersonating_user with no extra powers' do
        it 'is forbidden if roles do not match' do
          get 'show', params: { :id => @druid }
          expect(response.code).to eq('403')  # Forbidden
          expect(response.body).to include 'forbidden'
        end
        it 'succeeds if roles match' do
          allow(user).to receive(:roles).with(@apo_druid).and_return(['dor-viewer'])
          get 'show', params: { :id => @druid }
          expect(response.code).to eq('200')
        end
      end
      it_behaves_like 'APO-independent auth'
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

  describe 'error handling' do
    let(:druid) { 'druid:zz999zz9999' }
    it 'should 404 on missing item' do
      allow(subject).to receive(:current_user).and_return(double('WebAuth', is_admin?: true))
      expect(Dor).to receive(:find).with(druid).and_raise(ActiveFedora::ObjectNotFoundError)
      get 'show', params: { :id => druid }
      expect(response).to have_http_status(:not_found)
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
        expect(user).to receive(:is_admin?).and_return(true)
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
