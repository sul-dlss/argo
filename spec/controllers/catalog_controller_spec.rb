require 'spec_helper'

describe CatalogController, :type => :controller do
  before :each do
    @item = instantiate_fixture('rn653dy9317', Dor::Item)
    allow(Dor).to receive(:find).with(@item.pid, {}).and_return(@item)
    webauth = double(
      'WebAuth',
      login: 'sunetid',
      logged_in?: true,
      attributes: {'DISPLAYNAME' => 'Example User'},
      privgroup: ''
    )
    @user = User.find_or_create_by_webauth(webauth)
    allow(subject).to receive(:current_user).and_return(@user)
  end

  shared_examples 'APO-independent auth' do
    describe 'no user' do
      it 'basic get redirects to login' do
        expect(subject).to receive(:current_user).and_return(nil)
        get 'show', :id => @item.pid
        expect(response.code).to eq('401')  # Unauthorized, no place to redirect
      end
    end
    describe 'with user (valid_user)' do
      before :each do
        expect(subject).to receive(:valid_user?).with(@item).and_call_original # called every time
        allow(subject).to receive(:current_user).and_return(@user)
      end
      it 'unauthorized_user' do
        get 'show', :id => @item.pid
        expect(response.code).to eq('403')  # two different flavors
      end
      it 'is_admin' do
        allow(@user).to receive(:is_admin).and_return(true)
        get 'show', :id => @item.pid
        expect(response.code).to eq('200')
      end
      it 'is_viewer' do
        allow(@user).to receive(:is_viewer).and_return(true)
        get 'show', :id => @item.pid
        expect(response.code).to eq('200')
      end
      it 'impersonating nobody' do
        @user.set_groups_to_impersonate(['some:irrelevance'])
        get 'show', :id => @item.pid
        expect(response.code).to eq('403')
      end
      it 'impersonating viewer' do
        @user.set_groups_to_impersonate(['some:irrelevance', 'workgroup:sdr:viewer-role'])
        get 'show', :id => @item.pid
        expect(response.code).to eq('200')
      end
      it 'impersonating admin' do
        @user.set_groups_to_impersonate(['some:irrelevance', 'workgroup:sdr:administrator-role'])
        get 'show', :id => @item.pid
        expect(response.code).to eq('200')
      end
    end
  end

  describe '#show enforces permissions' do
    describe 'without APO' do
      before :each do
        allow(@item).to receive(:admin_policy_object).and_return(nil)
      end
      describe 'impersonating user with no extra powers' do
        it 'is forbidden since there is no APO' do
          allow(subject).to receive(:current_user).and_return(@user)
          get 'show', :id => @item.pid
          expect(response.code).to eq('403')  # Forbidden
          expect(response.body).to include 'No APO'
        end
      end
      it_behaves_like 'APO-independent auth'
    end

    describe 'with APO' do
      before :each do
        @apo = instantiate_fixture('hv992ry2431', Dor::AdminPolicyObject)
        allow(@item).to receive(:admin_policy_object).and_return(@apo)
      end
      describe 'impersonating_user with no extra powers' do
        it 'is forbidden if roles do not match' do
          allow(@user).to receive(:roles).with(@apo.pid).and_return([])
          get 'show', :id => @item.pid
          expect(response.code).to eq('403')  # Forbidden
          expect(response.body).to include 'forbidden'
        end
        it 'succeeds if roles match' do
          allow(@user).to receive(:roles).with(@apo.pid).and_return(['dor-viewer'])
          get 'show', :id => @item.pid
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
      expect(subject).to receive(:current_user).and_return(double('WebAuth', is_admin: true)).twice
      expect(Dor).to receive(:find).with(druid, {}).and_raise(ActiveFedora::ObjectNotFoundError)
      get 'show', :id => druid
      expect(response).to have_http_status(:not_found)
    end
  end
end
