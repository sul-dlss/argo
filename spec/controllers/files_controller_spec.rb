# frozen_string_literal: true

require 'rails_helper'

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
    context 'when they have manage access' do
      let(:object_client) { instance_double(Dor::Services::Client::Object, files: files_client) }
      let(:files_client) { instance_double(Dor::Services::Client::Files, retrieve: 'abc') }

      before do
        allow(controller).to receive(:authorize!).and_return(true)
        allow(Dor::Services::Client).to receive(:object).and_return(object_client)
        allow(Time).to receive(:now).and_return(Time.parse('Mon, 30 Nov 2015 20:19:43 UTC'))
      end

      it 'has dor-services-app fetch a file from the workspace' do
        get :show, params: { id: 'somefile.txt', item_id: pid }

        expect(files_client).to have_received(:retrieve).with(filename: 'somefile.txt')

        expect(response.headers['Last-Modified']).to eq 'Mon, 30 Nov 2015 20:19:43 -0000'
        expect(response.headers['Content-Disposition']).to eq 'attachment; filename=somefile.txt'
        expect(response.body).to eq 'abc'
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
    context 'when they have manage access' do
      let(:mock_file_name) { 'preserved_file.txt' }
      let(:mock_version) { '2' }
      let(:mock_content) { 'preserved file content' }

      before do
        allow(controller).to receive(:authorize!).and_return(true)
        allow(Preservation::Client.objects).to receive(:content)
          .with(druid: pid, filepath: mock_file_name, version: mock_version)
          .and_return(mock_content)
      end

      it 'returns a response with the preserved file content as the body and the right headers' do
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
      expect_any_instance_of(Dor::Services::Client::Files).to receive(:list).and_return(['foo.jp2', 'bar.jp2'])
      get :index, params: { item_id: pid, id: 'foo.jp2' }
      expect(response).to have_http_status(:ok)
      expect(assigns(:available_in_workspace)).to be_truthy
      expect(assigns(:object)).to respond_to(:contentMetadata)
    end

    it 'handles missing files in the workspace' do
      expect_any_instance_of(Dor::Services::Client::Files).to receive(:list).and_return(['foo.jp2', 'bar.jp2'])
      get :index, params: { item_id: pid, id: 'bar.tif' }
      expect(response).to have_http_status(:ok)
      expect(assigns(:available_in_workspace)).to be_falsey
      expect(assigns(:object)).to respond_to(:contentMetadata)
    end
  end
end
