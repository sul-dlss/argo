require 'spec_helper'

describe CatalogController, :type => :controller do

  before :each do
    @pid = 'rn653dy9317'  # a fixture Dor::Item record
    @druid = DruidTools::Druid.new(@pid).druid
    @item = instantiate_fixture(@pid, Dor::Item)
    allow(Dor).to receive(:find).with(@druid).and_return(@item)
    allow(Dor::Item).to receive(:find).with(@druid).and_return(@item)
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

  # These specs do not depend on an APO to authorize privileged roles.
  # Argo has global privileges based on webauth groups.
  shared_examples 'APO-independent auth' do
    describe 'no user' do
      it 'basic get redirects to login' do
        expect(subject).to receive(:current_user).and_return(nil)
        get 'show', :id => @pid
        expect(response.code).to eq('401')  # Unauthorized, no place to redirect
      end
    end
    describe 'with valid user' do
      before :each do
        expect(subject).to receive(:valid_user?).with(@item).and_call_original # called every time
      end
      it 'unauthorized_user' do
        get 'show', :id => @pid
        expect(response.code).to eq('403')  # two different flavors
        # expect(response.body).to include 'No APO'
      end
      it 'is_admin' do
        allow(@user).to receive(:is_admin).and_return(true)
        expect(@user).not_to receive(:is_manager)
        expect(@user).not_to receive(:is_viewer)
        get 'show', :id => @pid
        expect(response.code).to eq('200')
      end
      it 'is_manager' do
        allow(@user).to receive(:is_admin).and_return(false)
        allow(@user).to receive(:is_manager).and_return(true)
        expect(@user).not_to receive(:is_viewer)
        get 'show', :id => @pid
        expect(response.code).to eq('200')
      end
      it 'is_viewer' do
        allow(@user).to receive(:is_admin).and_return(false)
        allow(@user).to receive(:is_manager).and_return(false)
        allow(@user).to receive(:is_viewer).and_return(true)
        get 'show', :id => @pid
        expect(response.code).to eq('200')
      end
    end
  end

  # These specs all depend on an APO that can validate that a user
  # is authorized for privileged roles.  These roles depend on
  # methods and roles defined in Dor::Governable
  shared_examples 'APO-dependent auth' do
    describe 'with valid user' do
      before :each do
        expect(subject).to receive(:valid_user?).with(@item).and_call_original # called every time
        allow(@user).to receive(:is_admin).and_return(false)
        allow(@user).to receive(:is_manager).and_return(false)
        allow(@user).to receive(:is_viewer).and_return(false)
      end
      it 'impersonating admin' do
        # TODO: groups_which_admin_item to exclude managers?
        roles = @item.groups_which_manage_item
        allow(@user).to receive(:roles).and_return(roles)
        get 'show', :id => @pid
        expect(response.code).to eq('200')
      end
      it 'impersonating manager' do
        roles = @item.groups_which_manage_item
        allow(@user).to receive(:roles).and_return(roles)
        get 'show', :id => @pid
        expect(response.code).to eq('200')
      end
      it 'impersonating viewer' do
        roles = ['sdr-viewer']
        allow(@user).to receive(:roles).and_return(roles)
        get 'show', :id => @pid
        expect(response.code).to eq('200')
      end
      it 'impersonating nobody' do
        allow(@user).to receive(:roles).and_return([])
        get 'show', :id => @pid
        expect(response.code).to eq('403')
      end
    end
  end

  describe '#show enforces permissions' do
    context 'without a governing APO' do
      describe 'item is not an APO' do
        before :each do
          allow(@item).to receive(:admin_policy_object).and_return(nil)
        end
        describe 'user without authorized role' do
          it 'is forbidden since there is no APO' do
            get 'show', :id => @pid
            expect(response.code).to eq('403') # Forbidden
            expect(response.body).to include 'Item has no APO that allows access'
          end
        end
        it_behaves_like 'APO-independent auth'
        # No user roles can be tested because there is no APO to validate them.
        # So it cannot behave like 'APO-dependent auth'
      end

      describe 'item is an APO' do
        before :each do
          @item = instantiate_fixture(@druid, Dor::AdminPolicyObject)
          allow(@item).to receive(:admin_policy_object).and_return(nil)
          allow(Dor).to receive(:find).with(@pid).and_return(@item)
        end

        describe 'impersonating user with no extra powers' do
          it 'is forbidden since there is no role in this APO' do
            expect(@item).to be_instance_of Dor::AdminPolicyObject
            get 'show', :id => @pid
            expect(response.code).to eq('403') # Forbidden
            expect(response.body).to include 'Item is an APO that forbids access'
          end
        end
        it_behaves_like 'APO-independent auth'
        it_behaves_like 'APO-dependent auth'
      end
    end

    context 'with a governing APO' do
      before :each do
        @apo_pid = 'hv992ry2431'
        @apo_druid = 'druid:hv992ry2431'
        @apo = instantiate_fixture(@apo_pid, Dor::AdminPolicyObject)
        allow(@item).to receive(:admin_policy_object).and_return(@apo)
      end

      describe 'impersonating_user with no extra powers' do
        it 'is forbidden if roles do not match' do
          allow(@user).to receive(:roles).with(@apo_druid).and_return([])
          get 'show', :id => @pid
          expect(response.code).to eq('403')  # Forbidden
          expect(response.body).to include 'APO forbids access'
        end

        it 'succeeds if roles match' do
          roles = ['sdr-viewer']
          allow(@user).to receive(:roles).with(@apo_druid).and_return(roles)
          get 'show', :id => @pid
          expect(response.code).to eq('200')
        end
      end
      it_behaves_like 'APO-independent auth'
      it_behaves_like 'APO-dependent auth'
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
    let(:pid) { 'zz999zz9999' }
    let(:druid) { "druid:#{pid}" }
    it 'should 404 on missing item' do
      allow(subject).to receive(:current_user).and_return(admin_user)
      allow(Dor).to receive(:find).with(druid).and_raise(ActiveFedora::ObjectNotFoundError)
      allow(Dor::Item).to receive(:find).with(druid).and_raise(ActiveFedora::ObjectNotFoundError)
      get 'show', :id => pid
      expect(response).to have_http_status(:not_found)
    end
  end
end
