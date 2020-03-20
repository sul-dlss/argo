# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FilesController, type: :controller do
  let(:pid) { 'druid:rn653dy9317' }
  let(:item) { Dor::Item.new pid: pid }

  before do
    allow_any_instance_of(User).to receive(:roles).and_return([])
    sign_in user
  end

  let(:user) { create(:user) }

  describe '#show' do
    before do
      allow(Dor).to receive(:find).with(pid).and_return(item)
    end

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
    before do
      allow(Dor).to receive(:find).with(pid).and_return(item)
    end

    context 'when they have manage access' do
      let(:mock_file_name) { 'preserved file.txt' }
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
        expect(response.headers['Content-Disposition']).to eq("attachment; filename=#{CGI.escape(mock_file_name)}")
        expect(response.code).to eq('200')
        expect(response.body).to eq(mock_content)
      end

      context 'when file not found in preservation' do
        let(:errmsg) { 'it is fooched.' }

        before do
          allow(Preservation::Client.objects).to receive(:content)
            .with(druid: pid, filepath: 'not_there.txt', version: mock_version)
            .and_raise(Preservation::Client::NotFoundError, errmsg)
        end

        it 'returns 404 with error information' do
          get :preserved, params: { id: 'not_there.txt', version: mock_version, item_id: pid }
          expect(response.headers['Content-Type']).to eq('text/plain; charset=utf-8')
          expect(response.headers['Last-Modified']).to eq nil
          expect(response.headers['Content-Disposition']).to eq nil
          expect(response.code).to eq('404')
          expect(response.body).to eq("Preserved file not found: #{errmsg}")
        end
      end

      context 'when preservation-client raises an error other than NotFoundError' do
        let(:errmsg) { 'something is busted' }

        before do
          allow(Preservation::Client.objects).to receive(:content)
            .with(druid: pid, filepath: 'not_there.txt', version: mock_version)
            .and_raise(Preservation::Client::UnexpectedResponseError, errmsg)
          allow(Rails.logger).to receive(:error)
          allow(Honeybadger).to receive(:notify)
        end

        it 'renders an HTTP 500 message' do
          get :preserved, params: { id: 'not_there.txt', version: mock_version, item_id: pid }
          expect(Rails.logger).to have_received(:error)
            .with(/Preservation client error getting content of not_there.txt for #{pid} \(version #{mock_version}\)\: #{errmsg}/).once
          expect(Honeybadger).to have_received(:notify).with(/Preservation client error getting content of not_there.txt for #{pid} \(version #{mock_version}\)\: #{errmsg}/).once
          expect(response).to have_http_status(:internal_server_error)
          expect(response.body).to eq "Preservation client error getting content of not_there.txt for #{pid} (version #{mock_version}): #{errmsg}"
        end
      end
    end
  end

  describe '#index' do
    let(:workflow_client) { instance_double(Dor::Workflow::Client, lifecycle: true) }

    before do
      allow(Dor::Workflow::Client).to receive(:new).and_return(workflow_client)
    end

    it 'requires an id parameter' do
      expect { get :index, params: { item_id: pid } }.to raise_error(ArgumentError)
    end

    context 'when the files are in preservation' do
      before do
        allow(Preservation::Client.objects).to receive(:current_version).with(pid).and_return('7')
      end

      context 'when the files are in the workspace' do
        it 'sets available_in_workspace to true' do
          expect_any_instance_of(Dor::Services::Client::Files).to receive(:list).and_return(['M1090_S15_B01_F07_0106.jp2', 'bar.jp2'])
          get :index, params: { item_id: pid, id: 'M1090_S15_B01_F07_0106.jp2' }
          expect(response).to have_http_status(:ok)
          expect(assigns(:available_in_workspace)).to be true
          expect(assigns(:has_been_accessioned)).to be true
          expect(assigns(:last_accessioned_version)).to eq '7'
          expect(assigns(:file)).to respond_to(:administrative)
        end
      end

      context 'when files are missing from the workspace' do
        it 'sets available_in_workspace to false' do
          expect_any_instance_of(Dor::Services::Client::Files).to receive(:list).and_return(['foo.jp2', 'bar.jp2'])
          get :index, params: { item_id: pid, id: 'M1090_S15_B01_F07_0106.jp2' }
          expect(response).to have_http_status(:ok)
          expect(assigns(:available_in_workspace)).to be false
          expect(assigns(:file)).to respond_to(:administrative)
        end
      end
    end

    context 'when files are not in preservation' do
      before do
        allow(Preservation::Client.objects).to receive(:current_version).with(pid).and_raise(Preservation::Client::NotFoundError)
      end

      it 'renders an HTTP 422 message' do
        expect_any_instance_of(Dor::Services::Client::Files).to receive(:list).and_return(['foo.jp2', 'bar.jp2'])
        get :index, params: { item_id: pid, id: 'bar.tif' }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to eq "Preservation has not yet received #{pid}"
      end
    end

    context 'when preservation-client raises an error other than NotFoundError' do
      before do
        allow(Preservation::Client.objects).to receive(:current_version).with(pid).and_raise(Preservation::Client::UnexpectedResponseError, 'something is busted')
        allow(Rails.logger).to receive(:error)
        allow(Honeybadger).to receive(:notify)
      end

      it 'renders an HTTP 500 message' do
        expect_any_instance_of(Dor::Services::Client::Files).to receive(:list).and_return(['foo.jp2', 'bar.jp2'])
        get :index, params: { item_id: pid, id: 'bar.tif' }
        expect(Rails.logger).to have_received(:error).with(/something is busted/).once
        expect(Honeybadger).to have_received(:notify).with(/something is busted/).once
        expect(response).to have_http_status(:internal_server_error)
        expect(response.body).to eq "Preservation client error getting current version of #{pid}: something is busted"
      end
    end
  end
end
