# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'BulkActionsController' do
  let(:current_user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:rendered) { Capybara::Node::Simple.new(response.body) }

  before do
    sign_in current_user
  end

  describe 'GET index' do
    before do
      create(:bulk_action, user: other_user, description: 'not mine') # Not current_user's
      create(:bulk_action, user: current_user, description: 'Belongs to me')
    end

    it 'lists the BulkActions from current_user' do
      get '/bulk_actions'
      expect(response).to have_http_status :ok
      expect(response.body).to include 'Belongs to me'
      expect(response.body).not_to include 'not mine'
    end

    it 'shows a button to create a new one' do
      get '/bulk_actions?action=index&controller=catalog&f[current_version_isi][]=3&f[is_governed_by_ssim][]=info%3Afedora%2Fdruid%3Azw306xn5593&f[objectType_ssim][]=item&page=3'
      # this tests that page, action and controller are stripped out of the parameters
      url = '/bulk_actions/new?f%5Bcurrent_version_isi%5D%5B%5D=3&f%5Bis_governed_by_ssim%5D%5B%5D=info%3Afedora%2Fdruid%3Azw306xn5593&f%5BobjectType_ssim%5D%5B%5D=item'
      expect(rendered).to have_link 'New Bulk Action', href: url
    end

    it 'shows a button without bulk action form params' do
      get '/bulk_actions?action=index&controller=catalog&f[current_version_isi][]=3&f[is_governed_by_ssim][]=info%3Afedora%2Fdruid%3Azw306xn5593&f[objectType_ssim][]=item&page=3&download_access=world&view_access=stanford'
      # this tests that form params for download_access and view_access, in addition to page, action and controller are stripped out of the parameters
      url = '/bulk_actions/new?f%5Bcurrent_version_isi%5D%5B%5D=3&f%5Bis_governed_by_ssim%5D%5B%5D=info%3Afedora%2Fdruid%3Azw306xn5593&f%5BobjectType_ssim%5D%5B%5D=item'
      expect(rendered).to have_link 'New Bulk Action', href: url
    end
  end

  describe 'GET new' do
    it 'has a 200 status code' do
      get '/bulk_actions/new'
      expect(response).to have_http_status :ok
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
      b_action = create(:bulk_action, user: other_user)
      expect do
        delete "/bulk_actions/#{b_action.id}"
      end.not_to change(BulkAction, :count)
      expect(response).to have_http_status :not_found
    end
  end

  describe 'GET file' do
    let(:bulk_action) { create(:bulk_action, user_id:) }
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

      expect(response).to have_http_status :ok
    end

    context 'for other users files' do
      let(:user_id) { other_user.id }

      it 'does not send file for other users files' do
        get "/bulk_actions/#{bulk_action.id}/file?filename=not_my_log.log"

        expect(response).to have_http_status :not_found
      end
    end
  end
end
