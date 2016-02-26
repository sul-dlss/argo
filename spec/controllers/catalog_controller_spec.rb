require 'spec_helper'

describe CatalogController, :type => :controller do

  let(:item) do
    object = instantiate_fixture('rn653dy9317', Dor::Item)
    allow(Dor).to receive(:find).with(object.pid).and_return(object)
    object
  end
  let(:apo) do
    object = instantiate_fixture('hv992ry2431', Dor::AdminPolicyObject)
    allow(Dor).to receive(:find).with(object.pid).and_return(object)
    object
  end
  let(:current_user) do
    webauth = double(
      'WebAuth',
      login: 'sunetid',
      logged_in?: true,
      attributes: {'DISPLAYNAME' => 'Example User'},
      privgroup: ''
    )
    user = User.find_or_create_by_webauth(webauth)
    allow(subject).to receive(:current_user).and_return(user)
    user
  end

  # These specs do not depend on an APO to authorize privileged roles.
  # Argo has global privileges based on webauth groups.
  shared_examples 'APO-independent auth for show' do
    context 'no user' do
      it 'basic get redirects to login' do
        # ApplicationController#authorize! returns :unauthorized
        expect(subject).not_to receive(:valid_user?)
        expect(subject).to receive(:current_user).and_return(nil)
        get 'show', :id => item.pid
        expect(response).to have_http_status(:unauthorized)
      end
    end
    context 'with valid user' do
      before :each do
        # Ensure the `current_user` is instantiated for all these examples
        expect(current_user).to receive('can_view?').with(item).and_call_original
        expect(subject).to receive(:valid_user?).with(item).and_call_original
      end
      it 'unauthorized_user' do
        # CatalogController#valid_user? returns :forbidden
        get 'show', :id => item.pid
        expect(response).to have_http_status(:forbidden)
      end
      it 'is_admin' do
        expect(current_user).to receive(:is_admin).at_least(:once).and_return(true)
        expect(current_user).not_to receive(:is_manager)
        expect(current_user).not_to receive(:is_viewer)
        get 'show', :id => item.pid
        expect(response).to have_http_status(:ok)
      end
      it 'is_manager' do
        expect(current_user).to receive(:is_admin).at_least(:once).and_return(false)
        expect(current_user).to receive(:is_manager).at_least(:once).and_return(true)
        expect(current_user).not_to receive(:is_viewer)
        get 'show', :id => item.pid
        expect(response).to have_http_status(:ok)
      end
      it 'is_viewer' do
        expect(current_user).to receive(:is_admin).at_least(:once).and_return(false)
        expect(current_user).to receive(:is_manager).at_least(:once).and_return(false)
        expect(current_user).to receive(:is_viewer).at_least(:once).and_return(true)
        get 'show', :id => item.pid
        expect(response).to have_http_status(:ok)
      end
    end
  end

  # These specs all depend on an APO that can validate that a user
  # is authorized for privileged roles.  These roles depend on
  # methods and roles defined in Dor::Governable
  shared_examples 'APO-dependent auth for show' do
    context 'with valid user' do
      before :each do
        allow(current_user).to receive(:is_admin).and_return(false)
        allow(current_user).to receive(:is_manager).and_return(false)
        allow(current_user).to receive(:is_viewer).and_return(false)
      end
      it 'impersonating admin' do
        skip 'TODO: enable Dor::Governable#groups_which_admin_item to exclude managers'
        # If Dor::Governable#groups_which_admin_item exists, enable this spec.
        # roles = item.groups_which_admin_item
        # expect(current_user).to receive(:roles).with(apo.pid).at_least(:once).and_return(roles)
        # get 'show', :id => item.pid
        # expect(response).to have_http_status(:ok)
      end
      it 'impersonating manager' do
        roles = item.groups_which_manage_item
        expect(current_user).to receive(:roles).with(apo.pid).at_least(:once).and_return(roles)
        get 'show', :id => item.pid
        expect(response).to have_http_status(:ok)
      end
      it 'impersonating viewer' do
        roles = ['sdr-viewer']
        expect(current_user).to receive(:roles).with(apo.pid).at_least(:once).and_return(roles)
        get 'show', :id => item.pid
        expect(response).to have_http_status(:ok)
      end
      it 'impersonating nobody' do
        expect(current_user).to receive(:roles).with(apo.pid).at_least(:once).and_return([])
        get 'show', :id => item.pid
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe '#show enforces permissions' do
    context 'without a governing APO' do
      context 'item is not an APO' do
        before :each do
          allow(item).to receive(:admin_policy_object).and_return(nil)
          expect(current_user).not_to receive(:roles)
        end
        describe 'user without authorized role' do
          it 'is forbidden since there is no APO' do
            get 'show', :id => item.pid
            expect(response).to have_http_status(:forbidden)
            expect(response.body).to include 'Item has no APO that allows access'
          end
        end
        it_behaves_like 'APO-independent auth for show'
        # No user roles can be tested because there is no APO to validate them.
        # So it cannot behave like 'APO-dependent auth'
      end

      context 'item is an APO' do
        # Override the definition of `item` so it's an APO without a governing
        # APO.  It must be `item` for the shared examples used in this context.
        # So this let(:item) effectively assigns `item = apo`.
        # In the shared examples, the `user.roles` should receive the `apo.pid`
        # only because the `item == apo`; so there is no point in these specs
        # expecting `current_user.roles(item.pid)`
        # instead of `current_user.roles(apo.pid)`
        # although they could (and they must if `item != apo`).
        let(:item) do
          allow(apo).to receive(:admin_policy_object).and_return(nil)
          apo
        end
        describe 'impersonating user with no extra powers' do
          it 'is forbidden since there is no role in this APO' do
            expect(item).to be_instance_of Dor::AdminPolicyObject
            expect(current_user).to receive(:roles).with(item.pid).at_least(:once).and_return([])
            get 'show', :id => item.pid
            expect(response).to have_http_status(:forbidden)
            expect(response.body).to include 'Item is an APO that forbids access'
          end
        end
        # These shared examples all use the `item` defined in the most
        # recent `let(:item)`, so that will be the apo, as noted above.
        it_behaves_like 'APO-independent auth for show'
        it_behaves_like 'APO-dependent auth for show'
      end
    end

    context 'with a governing APO' do
      before :each do
        # Ensure the APO for `item` is an instantiated APO fixture, which
        # is defined in the overall context at the top of this file.
        allow(item).to receive(:admin_policy_object).and_return(apo)
      end

      describe 'impersonating_user with no extra powers' do
        it 'is forbidden if roles do not match' do
          allow(current_user).to receive(:roles).with(apo.pid).and_return([])
          get 'show', :id => item.pid
          expect(response).to have_http_status(:forbidden)
          expect(response.body).to include 'APO forbids access'
        end

        it 'succeeds if roles match' do
          roles = ['sdr-viewer']
          allow(current_user).to receive(:roles).with(apo.pid).and_return(roles)
          get 'show', :id => item.pid
          expect(response.code).to eq('200')
        end
      end
      it_behaves_like 'APO-independent auth for show'
      it_behaves_like 'APO-dependent auth for show'
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
    before :each do
      allow(subject).to receive(:current_user).and_return(admin_user)
    end
    it 'should 404 on missing item' do
      pid = 'druid:zz999zz9999'
      expect(Dor).to receive(:find).with(pid).and_raise(ActiveFedora::ObjectNotFoundError)
      get 'show', :id => pid
      expect(response).to have_http_status(:not_found)
    end
    it 'should add a "druid:" prefix for an ID without it' do
      pid = item.pid.sub('druid:', '')
      expect(Dor).to receive(:find).with("druid:#{pid}").and_call_original
      get 'show', :id => pid
      expect(response).to have_http_status(:ok)
    end
  end
end
