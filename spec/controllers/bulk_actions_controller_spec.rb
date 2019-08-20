# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActionsController do
  let(:current_user) do
    create(:user)
  end

  before do
    sign_in current_user
  end

  describe 'GET index' do
    it 'assigns @bulk_actions from current_user' do
      create(:bulk_action, user_id: current_user.id + 1) # Not current_user's
      b_action = create(:bulk_action, user: current_user)
      get :index
      expect(assigns(:bulk_actions)).to eq [b_action]
    end
    it 'has a 200 status code' do
      get :index
      expect(response.status).to eq 200
    end
  end

  describe 'GET new' do
    it 'assigns @bulk_action' do
      get :new
      expect(assigns(:bulk_action)).not_to be_nil
    end
    describe 'assigns @last_search' do
      it 'with no session[:search]' do
        first_search = Search.create
        last_search = Search.create
        searches = [last_search, first_search] # Ordered desc from Blacklight
        expect(subject).to receive(:searches_from_history).and_return searches
        expect(request.session[:search]).to be_nil
        get :new
        expect(assigns(:last_search)).to be_an Search
        expect(assigns(:last_search)).to eq last_search
      end
      it 'with last session[:search]' do
        Search.create
        request.session[:search] = { 'id' => 1 }
        all_searches = Search.all
        expect(all_searches).to receive(:find).with(1)
        expect(subject).to receive(:searches_from_history).and_return all_searches
        get :new
      end
    end

    it 'has a 200 status code' do
      get :new
      expect(response.status).to eq 200
    end
  end

  describe 'POST create' do
    context 'with correct parameters' do
      let(:groups) { [User::ADMIN_GROUPS.first, 'sunetid:person9'] }

      before do
        allow_any_instance_of(User).to receive(:groups).and_return(groups)
      end

      it 'assigns @bulk_action to current_user and passes current groups, prepending druid: to all pids if missing' do
        post :create, params: { bulk_action: { action_type: 'GenericJob', pids: "a\nb\nc" } }
        expect(assigns(:bulk_action)).to be_an BulkAction
        expect(assigns(:bulk_action).user).to eq current_user
        expect(assigns(:bulk_action).groups).to eq groups
        expect(assigns(:bulk_action).pids).to eq "druid:a\ndruid:b\ndruid:c"
      end

      it 'assigns @bulk_action to current_user and passes current groups, leaving pids alone if druid: prefix exists' do
        post :create, params: { bulk_action: { action_type: 'GenericJob', pids: "druid:a\nb\ndruid:c" } }
        expect(assigns(:bulk_action)).to be_an BulkAction
        expect(assigns(:bulk_action).user).to eq current_user
        expect(assigns(:bulk_action).groups).to eq groups
        expect(assigns(:bulk_action).pids).to eq "druid:a\ndruid:b\ndruid:c"
      end

      it 'assigns @bulk_action with catkeys passed in from form' do
        post :create, params: { bulk_action: { action_type: 'ManageCatkeyJob', pids: '', 'manage_catkeys[catkeys]' => "1234\n5678" } }
        expect(assigns(:bulk_action)).to be_an BulkAction
        expect(assigns(:bulk_action).manage_catkeys).to eq('catkeys' => "1234\n5678")
      end

      it 'creates a new BulkAction' do
        expect do
          post :create, params: { bulk_action: { action_type: 'GenericJob', pids: '' } }
        end.to change(BulkAction, :count).by(1)
      end
      it 'has a 302 status code' do
        post :create, params: { bulk_action: { action_type: 'GenericJob', pids: '' } }
        expect(response.status).to eq 302
      end
      it 'when not saveable render new' do
        fake_bulk_action = double('fake', save: false, 'user=' => nil)
        expect(BulkAction).to receive(:new).and_return fake_bulk_action
        post :create, params: { bulk_action: { action_type: 'GenericJob' } }
        expect(response).to render_template('new')
      end
    end

    context 'without current parameters' do
      it 'requires bulk_action parameter' do
        expect { post :create }.to raise_error ActionController::ParameterMissing
      end
    end
  end

  describe 'DELETE destroy' do
    it 'assigns and deletes current_users BulkAction by id param' do
      b_action = create(:bulk_action, user: current_user)
      expect do
        delete :destroy, params: { id: b_action.id }
      end.to change(BulkAction, :count).by(-1)
    end
    it 'does not delete other users bulk actions' do
      b_action = create(:bulk_action, user_id: current_user.id + 1)
      expect do
        delete :destroy, params: { id: b_action.id }
      end.not_to change(BulkAction, :count)
      expect(response.status).to eq 404
    end
  end

  describe 'GET file' do
    let(:bulk_action) { create(:bulk_action, user_id: user_id) }
    let(:user_id) { current_user.id }
    let(:file) { bulk_action.file('test.log') }

    before do
      FileUtils.mkdir_p(bulk_action.output_directory)
      File.open(file, 'w')
    end

    after do
      File.delete(file)
    end

    it 'sends through a BulkActions file' do
      get :file, params: { id: bulk_action.id, filename: 'test.log', mime_type: 'text/plain' }
      expect(response.status).to eq 200
    end

    context 'for other users files' do
      let(:user_id) { current_user.id + 1 }

      it 'does not send file for other users files' do
        expect(controller).not_to receive(:send_file)
        get :file, params: { id: bulk_action.id, filename: 'not_my_log.log' }
        expect(response.status).to eq 404
      end
    end
  end
end
