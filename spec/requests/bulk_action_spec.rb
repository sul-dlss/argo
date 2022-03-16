# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'BulkActionsController' do
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
      get '/bulk_actions'
      expect(assigns(:bulk_actions)).to eq [b_action]
    end

    it 'has a 200 status code' do
      get '/bulk_actions'
      expect(response.status).to eq 200
    end
  end

  describe 'GET new' do
    it 'assigns @form' do
      get '/bulk_actions/new'
      expect(assigns(:form)).not_to be_nil
    end

    it 'has a 200 status code' do
      get '/bulk_actions/new'
      expect(response.status).to eq 200
    end
  end

  describe 'POST create' do
    context 'with correct parameters' do
      it 'creates a new BulkAction' do
        expect do
          post '/bulk_actions', params: { bulk_action: { action_type: 'GenericJob', pids: '' } }
        end.to change(BulkAction, :count).by(1)
      end

      it 'has a 302 status code' do
        post '/bulk_actions', params: { bulk_action: { action_type: 'GenericJob', pids: '' } }
        expect(response.status).to eq 302
      end

      context 'when not saveable' do
        before do
          fake_bulk_action = build(:bulk_action)
          allow(fake_bulk_action).to receive(:save).and_return(false)
          allow(BulkAction).to receive(:new).and_return fake_bulk_action
        end

        it 'renders new' do
          post '/bulk_actions', params: { bulk_action: { action_type: 'GenericJob' } }
          expect(response).to render_template('new')
        end
      end
    end

    context 'without current parameters' do
      it 'requires bulk_action parameter' do
        expect { post '/bulk_actions' }.to raise_error ActionController::ParameterMissing
      end
    end
  end

  describe 'DELETE destroy' do
    it 'assigns and deletes current_users BulkAction by id param' do
      b_action = create(:bulk_action, user: current_user)
      expect do
        delete "/bulk_actions/#{b_action.id}"
      end.to change(BulkAction, :count).by(-1)
    end

    it 'does not delete other users bulk actions' do
      b_action = create(:bulk_action, user_id: current_user.id + 1)
      expect do
        delete "/bulk_actions/#{b_action.id}"
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
      get "/bulk_actions/#{bulk_action.id}/file?filename=test.log"

      expect(response.status).to eq 200
    end

    context 'for other users files' do
      let(:user_id) { current_user.id + 1 }

      it 'does not send file for other users files' do
        get "/bulk_actions/#{bulk_action.id}/file?filename=not_my_log.log"

        expect(response.status).to eq 404
      end
    end
  end
end