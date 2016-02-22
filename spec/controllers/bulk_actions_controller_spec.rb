require 'spec_helper'

describe BulkActionsController, :type => :controller do
  let(:current_user) { create(:user) }
  before(:each) do
    allow(subject).to receive(:current_user).and_return(current_user)
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
      expect(assigns(:bulk_action)).to_not be_nil
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
    it 'assigns @bulk_action to current_user' do
      post :create, bulk_action: {action_type: 'GenericJob', pids: ''}
      expect(assigns(:bulk_action)).to be_an BulkAction
      expect(assigns(:bulk_action).user).to eq current_user
    end
    it 'creates a new BulkAction' do
      expect do
        post :create, bulk_action: {action_type: 'GenericJob', pids: ''}
      end.to change(BulkAction, :count).by(1)
    end
    it 'has a 302 status code' do
      post :create, bulk_action: {action_type: 'GenericJob', pids: ''}
      expect(response.status).to eq 302
    end
    it 'requires bulk_action parameter' do
      expect{ post :create }.to raise_error ActionController::ParameterMissing
    end
    it 'when not saveable render new' do
      fake_bulk_action = double('fake', save: false, 'user=' => nil)
      expect(BulkAction).to receive(:new).and_return fake_bulk_action
      post :create, bulk_action: {action_type: 'GenericJob'}
      expect(response).to render_template('new')
    end
  end
  describe 'DELETE destroy' do
    it 'assigns and deletes current_users BulkAction by id param' do
      b_action = create(:bulk_action, user: current_user)
      expect do
        delete :destroy, id: b_action.id
      end.to change(BulkAction, :count).by(-1)
    end
    it 'does not delete other users bulk actions' do
      b_action = create(:bulk_action, user_id: current_user.id + 1)
      expect do
        delete :destroy, id: b_action.id
      end.to_not change(BulkAction, :count)
      expect(response.status).to eq 404
    end
  end
  describe 'GET file' do
    it 'sends through a BulkActions file' do
      b_action = create(:bulk_action, user: current_user)
      expect(controller).to receive(:render)
      expect(controller).to receive(:send_file)
      get :file, id: b_action.id, filename: 'test.log'
      expect(response.status).to eq 200
    end
    it 'does not send file for other users files' do
      b_action = create(:bulk_action, user_id: current_user.id + 1)
      expect(controller).to_not receive(:send_file)
      get :file, id: b_action.id, filename: 'not_my_log.log'
      expect(response.status).to eq 404
    end
  end
end
