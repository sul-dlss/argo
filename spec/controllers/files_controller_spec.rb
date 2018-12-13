# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FilesController, type: :controller do
  let(:pid) { 'druid:oo201oo0001' }
  let(:item) { Dor::Item.new pid: pid }

  before do
    allow_any_instance_of(User).to receive(:roles).and_return([])
    sign_in user
    allow(Dor).to receive(:find).with(pid).and_return(item)
  end

  let(:user) { create(:user) }

  describe '#show' do
    context 'when they have manage_content access' do
      before do
        allow(controller).to receive(:authorize!).and_return(true)
      end
      it 'has dor-services-app fetch a file from the workspace' do
        allow(item).to receive(:get_file).and_return('abc')
        expect(item).to receive(:get_file)
        allow(Time).to receive(:now).and_return(Time.parse('Mon, 30 Nov 2015 20:19:43 UTC'))
        get :show, params: { id: 'somefile.txt', item_id: pid }
        expect(response.headers['Last-Modified']).to eq 'Mon, 30 Nov 2015 20:19:43 -0000'
      end
    end

    context 'when the user can not view_content' do
      before do
        allow(controller).to receive(:authorize!).with(:view_content, Dor::Item).and_raise(CanCan::AccessDenied)
      end

      it 'returns a 403' do
        get :show, params: { id: 'somefile.txt', item_id: pid }
        expect(response.code).to eq('403')
      end
    end
  end

  describe '#preserved' do
    context 'when they have manage_content access' do
      before do
        allow(controller).to receive(:authorize!).and_return(true)
      end

      it 'returns a response with the preserved file content as the body and the right headers' do
        mock_file_name = 'preserved_file'
        mock_version = 2
        mock_content = 'preserved file content'
        allow(item).to receive(:get_preserved_file).with(mock_file_name, mock_version).and_return(mock_content)

        last_modified_lower_bound = Time.now.utc.rfc2822
        get :preserved, params: { id: mock_file_name, version: mock_version, item_id: pid }
        expect(response.headers['Last-Modified']).to be <= Time.now.utc.rfc2822
        expect(response.headers['Last-Modified']).to be >= last_modified_lower_bound
        expect(response.headers['Content-Type']).to eq('application/octet-stream')
        expect(response.headers['Content-Disposition']).to eq("attachment; filename=#{mock_file_name}")
        expect(response.code).to eq('200')
        expect(response.body).to eq(mock_content)
      end
    end
  end

  describe '#index' do
    it 'requires an id parameter' do
      expect { get :index, params: { item_id: pid } }.to raise_error(ArgumentError)
    end
    it 'checks for a file in the workspace' do
      expect(item).to receive(:list_files).and_return(['foo.jp2', 'bar.jp2'])
      get :index, params: { item_id: pid, id: 'foo.jp2' }
      expect(response).to have_http_status(:ok)
      expect(assigns(:available_in_workspace)).to be_truthy
      expect(assigns(:available_in_workspace_error)).to be_nil
    end
    it 'handles missing files in the workspace' do
      expect(item).to receive(:list_files).and_return(['foo.jp2', 'bar.jp2'])
      get :index, params: { item_id: pid, id: 'bar.tif' }
      expect(response).to have_http_status(:ok)
      expect(assigns(:available_in_workspace)).to be_falsey
      expect(assigns(:available_in_workspace_error)).to be_nil
    end
    it 'handles SFTP errors' do
      expect(item).to receive(:list_files).and_raise(Net::SSH::AuthenticationFailed)
      get :index, params: { item_id: pid, id: 'foo.jp2' }
      expect(response).to have_http_status(:ok)
      expect(assigns(:available_in_workspace)).to be_falsey
      expect(assigns(:available_in_workspace_error)).to match(/Net::SSH::AuthenticationFailed/)
    end
  end
end
