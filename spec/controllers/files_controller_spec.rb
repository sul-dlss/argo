# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FilesController, type: :controller do
  let(:pid) { 'druid:bc123df4567' }
  let(:cocina_model) do
    instance_double(Cocina::Models::DRO, externalIdentifier: pid, structural: structural)
  end
  let(:file_set) do
    instance_double(Cocina::Models::FileSet, structural: fs_structural)
  end
  let(:structural) do
    instance_double(Cocina::Models::DROStructural, contains: [file_set])
  end
  let(:fs_structural) do
    instance_double(Cocina::Models::FileSetStructural, contains: [file])
  end
  let(:file) do
    instance_double(Cocina::Models::File, externalIdentifier: "#{pid}/M1090_S15_B01_F07_0106.jp2")
  end
  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model) }

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    allow_any_instance_of(User).to receive(:roles).and_return([])
    sign_in user
  end

  let(:user) { create(:user) }

  describe '#preserved' do
    context 'when they have manage access' do
      let(:mock_file_name) { 'preserved file.txt' }
      let(:mock_version) { '2' }
      let(:mock_content) { 'preserved file content' }

      before do
        allow(controller).to receive(:authorize!).and_return(true)
        allow(Preservation::Client.objects).to receive(:content)
      end

      it 'returns a response with the preserved file content as the body and the right headers' do
        last_modified_lower_bound = Time.now.utc.rfc2822
        get :preserved, params: { id: mock_file_name, version: mock_version, item_id: pid }
        expect(response.headers['Last-Modified']).to be <= Time.now.utc.rfc2822
        expect(response.headers['Last-Modified']).to be >= last_modified_lower_bound
        expect(response.headers['Content-Type']).to eq('application/octet-stream')
        expect(response.headers['Content-Disposition']).to eq("attachment; filename=\"#{CGI.escape(mock_file_name)}\"")
        expect(response.code).to eq('200')
        expect(Preservation::Client.objects).to have_received(:content)
          .with(druid: pid, filepath: mock_file_name, version: mock_version, on_data: Proc)
      end

      context 'when file not found in preservation' do
        let(:errmsg) { 'it is fooched.' }

        before do
          allow(Preservation::Client.objects).to receive(:content)
            .and_raise(Preservation::Client::NotFoundError, errmsg)
        end

        it 'returns 404 with error information' do
          get :preserved, params: { id: 'not_there.txt', version: mock_version, item_id: pid }
          expect(response.headers['Content-Type']).to eq('application/octet-stream')
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
            .and_raise(Preservation::Client::UnexpectedResponseError, errmsg)
          allow(Rails.logger).to receive(:error)
          allow(Honeybadger).to receive(:notify)
        end

        it 'renders an HTTP 500 message' do
          get :preserved, params: { id: 'not_there.txt', version: mock_version, item_id: pid }
          expect(Rails.logger).to have_received(:error)
            .with(/Preservation client error getting content of not_there.txt for #{pid} \(version #{mock_version}\): #{errmsg}/).once
          expect(Honeybadger).to have_received(:notify).with(/Preservation client error getting content of not_there.txt for #{pid} \(version #{mock_version}\): #{errmsg}/).once
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

      it 'is successful' do
        get :index, params: { item_id: pid, id: 'M1090_S15_B01_F07_0106.jp2' }
        expect(response).to have_http_status(:ok)
        expect(assigns(:has_been_accessioned)).to be true
        expect(assigns(:last_accessioned_version)).to eq '7'
        expect(assigns(:file)).to eq file
      end
    end

    context 'when files are not in preservation' do
      before do
        allow(Preservation::Client.objects).to receive(:current_version).with(pid).and_raise(Preservation::Client::NotFoundError)
      end

      it 'renders an HTTP 422 message' do
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
        get :index, params: { item_id: pid, id: 'bar.tif' }
        expect(Rails.logger).to have_received(:error).with(/something is busted/).once
        expect(Honeybadger).to have_received(:notify).with(/something is busted/).once
        expect(response).to have_http_status(:internal_server_error)
        expect(response.body).to eq "Preservation client error getting current version of #{pid}: something is busted"
      end
    end
  end
end
