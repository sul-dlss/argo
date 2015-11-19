require 'spec_helper'

describe CatalogController, :type => :controller do

  before :each do
#   log_in_as_mock_user(subject)
    @druid = 'rn653dy9317'  # a fixture Dor::Item record
    @item = instantiate_fixture(@druid, Dor::Item)
    @user = User.find_or_create_by_webauth double('WebAuth', :login => 'sunetid', :logged_in? => true, :attributes => {'DISPLAYNAME' => 'Example User'}, :privgroup => "")
    allow(Dor).to receive(:find).with("druid:#{@druid}").and_return(@item)
    allow(Dor::Item).to receive(:find).with("druid:#{@druid}").and_return(@item)
  end

  shared_examples 'APO-independent auth' do
    describe 'no user' do
      it 'basic get redirects to login' do
        expect(subject).to receive(:webauth).and_return(nil)
        get 'show', :id => @druid
        expect(response.code).to eq('302')  # redirect for auth
      end
    end
    describe 'with user (valid_user)' do
      before :each do
        expect(subject).to receive(:valid_user?).with(@item).and_call_original # called every time
        allow(subject).to receive(:current_user).and_return(@user)
      end
      it 'unauthorized_user' do
        get 'show', :id => @druid
        expect(response.code).to eq('403')  # two different flavors
        # expect(response.body).to include 'No APO'
      end
      it 'is_admin' do
        allow(@user).to receive(:is_admin).and_return(true)
        get 'show', :id => @druid
        expect(response.code).to eq('200')
      end
      it 'is_viewer' do
        allow(@user).to receive(:is_viewer).and_return(true)
        get 'show', :id => @druid
        expect(response.code).to eq('200')
      end
      it 'impersonating nobody' do
        @user.set_groups_to_impersonate(['some:irrelevance'])
        get 'show', :id => @druid
        expect(response.code).to eq('403')
      end
      it 'impersonating viewer' do
        @user.set_groups_to_impersonate(['some:irrelevance', 'workgroup:sdr:viewer-role'])
        get 'show', :id => @druid
        expect(response.code).to eq('200')
      end
      it 'impersonating admin' do
        @user.set_groups_to_impersonate(['some:irrelevance', 'workgroup:sdr:administrator-role'])
        get 'show', :id => @druid
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
          get 'show', :id => @druid
          expect(response.code).to eq('403')  # Forbidden
          expect(response.body).to include 'No APO'
        end
      end
      it_behaves_like 'APO-independent auth'
    end

    describe 'with APO' do
      before :each do
        @apo_druid = 'druid:hv992ry2431'
        @apo = instantiate_fixture('hv992ry2431', Dor::AdminPolicyObject)
        allow(@item).to receive(:admin_policy_object).and_return(@apo)
        allow(@user).to receive(:roles).with(@apo_druid).and_return([])
      end
      describe 'impersonating_user with no extra powers' do
        it 'is forbidden if roles do not match' do
          allow(subject).to receive(:current_user).and_return(@user)
          get 'show', :id => @druid
          expect(response.code).to eq('403')  # Forbidden
          expect(response.body).to include 'forbidden'
        end
        it 'succeeds if roles match' do
          allow(@user).to receive(:roles).with(@apo_druid).and_return(['dor-viewer'])
          allow(subject).to receive(:current_user).and_return(@user)
          get 'show', :id => @druid
          expect(response.code).to eq('200')
        end
      end
      it_behaves_like 'APO-independent auth'
    end
  end
end
