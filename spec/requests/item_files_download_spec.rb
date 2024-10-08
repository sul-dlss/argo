# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Download item files' do
  let(:druid) { cocina_model.externalIdentifier }
  let(:cocina_model) do
    model = Cocina::Models.build(cocina_params.stringify_keys)
    Cocina::Models.with_metadata(model, 'abc123')
  end
  let(:state_service) { instance_double(StateService) }

  let(:cocina_params) do
    {
      type: Cocina::Models::ObjectType.image,
      externalIdentifier: 'druid:rn653dy9317',
      label: 'M1090_S15_B01_F07_0106',
      version:,
      description: {
        title: [{ value: 'M1090_S15_B01_F07_0106' }],
        purl: 'https://purl.stanford.edu/rn653dy9317'
      },
      access: {
        view: 'location-based',
        copyright: '© The Estate of R. Buckminster Fuller.',
        download: 'location-based',
        location: 'spec'
      },
      administrative: {
        hasAdminPolicy: 'druid:rd845kr7465'
      },
      identification: {
        sourceId: 'fuller:M1090_S15_B01_F07_0106'
      },
      structural: {
        contains: [
          {
            type: Cocina::Models::FileSetType.file,
            externalIdentifier: 'rn653dy9317_106',
            label: 'M1090_S15_B01_F07_0106',
            version: 4,
            structural: {
              contains: [
                {
                  type: Cocina::Models::ObjectType.file,
                  externalIdentifier: 'druid:rn653dy9317/M1090_S15_B01_F07_0106.jp2',
                  label: 'M1090_S15_B01_F07_0106.jp2',
                  filename: 'M1090_S15_B01_F07_0106.jp2',
                  size: 3_305_991,
                  version: 4,
                  hasMimeType: 'image/jp2',
                  hasMessageDigests: [
                    {
                      type: 'sha1',
                      digest: 'fd28e74b3139b04a0e5c5c3d3263598f629f8967'
                    },
                    {
                      type: 'md5',
                      digest: '244cbb3960407f59ac77a916870e0502'
                    }
                  ],
                  access: {
                    view: 'world',
                    download: 'world'
                  },
                  administrative: {
                    publish: true,
                    sdrPreserve: true,
                    shelve: true
                  },
                  presentation: {
                    height: 3426,
                    width: 5102
                  }
                },
                {
                  type: Cocina::Models::ObjectType.file,
                  externalIdentifier: 'druid:rn653dy9317/M1090_S15_B01_F07_0106.tif',
                  label: 'M1090_S15_B01_F07_0106.tif',
                  filename: 'M1090_S15_B01_F07_0106.tif',
                  size: 52_467_428,
                  version: 4,
                  hasMimeType: 'image/tiff',
                  hasMessageDigests: [
                    {
                      type: 'sha1',
                      digest: 'cf336c4f714b180a09bbfefde159d689e1d517bd'
                    },
                    {
                      type: 'md5',
                      digest: '56978088366e66f87d4d5a531f2fea04'
                    }
                  ],
                  access: {
                    view: 'dark',
                    download: 'none'
                  },
                  administrative: {
                    publish: false,
                    sdrPreserve: true,
                    shelve: false
                  },
                  presentation: {
                    height: 3426,
                    width: 5102
                  }
                }
              ]
            }
          }
        ],
        isMemberOf: [
          'druid:rh056sr3313'
        ]
      }
    }
  end
  let(:version) { 4 }
  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model) }
  let(:bare_druid) { druid.delete_prefix('druid:') }
  let(:user) { create(:user) }

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    allow(Preservation::Client.objects).to receive(:current_version).and_return(4)
    sign_in user
  end

  context 'when unauthorized' do
    it 'returns HTTP forbidden' do
      get download_item_files_path(druid)
      expect(response).to be_forbidden
    end
  end

  context 'when authorized' do
    let(:fake_sink) { instance_double(ZipTricks::Streamer::Writable, close: nil) }
    let(:fake_zip) { instance_double(ZipTricks::Streamer) }

    before do
      allow_any_instance_of(User).to receive(:manager?).and_return(true)
      allow(Preservation::Client.objects).to receive(:content)
      allow(ZipTricks::Streamer).to receive(:open).and_yield(fake_zip)
      allow(fake_zip).to receive(:write_deflated_file).and_yield(fake_sink)
      allow(Time).to receive(:now).and_return(Time.parse('2023-09-08 11:39:45 -0000'))
    end

    context 'when cocina head version' do
      it 'sets content-disposition header' do
        get download_item_files_path(druid)
        expect(response.headers.to_h).to include(
          'content-disposition' => "attachment; filename=\"#{bare_druid}.zip\"; filename*=UTF-8''#{bare_druid}.zip",
          'content-type' => 'application/zip',
          'x-accel-buffering' => 'no',
          'last-modified' => 'Fri, 08 Sep 2023 11:39:45 GMT'
        )
      end

      it 'zips files set for preservation' do
        get download_item_files_path(druid)
        expect(fake_zip).to have_received(:write_deflated_file).with('M1090_S15_B01_F07_0106.jp2').once
        expect(fake_zip).to have_received(:write_deflated_file).with('M1090_S15_B01_F07_0106.tif').once
        expect(Preservation::Client.objects).to have_received(:content).with(
          druid:,
          filepath: 'M1090_S15_B01_F07_0106.jp2',
          version:,
          on_data: Proc
        )
        expect(Preservation::Client.objects).to have_received(:content).with(
          druid:,
          filepath: 'M1090_S15_B01_F07_0106.tif',
          version:,
          on_data: Proc
        )
      end
    end

    context 'when cocina user version' do
      let(:user_version) { 2 }
      let(:version) { 3 }

      let(:object_client) { instance_double(Dor::Services::Client::Object, user_version: user_version_client) }
      let(:user_version_client) { instance_double(Dor::Services::Client::UserVersion, find: cocina_model) }

      it 'zips files set for preservation' do
        get download_item_public_version_files_path(druid, user_version)
        expect(fake_zip).to have_received(:write_deflated_file).with('M1090_S15_B01_F07_0106.jp2').once
        expect(fake_zip).to have_received(:write_deflated_file).with('M1090_S15_B01_F07_0106.tif').once
        expect(Preservation::Client.objects).to have_received(:content).with(
          druid:,
          filepath: 'M1090_S15_B01_F07_0106.jp2',
          version:,
          on_data: Proc
        )
        expect(Preservation::Client.objects).to have_received(:content).with(
          druid:,
          filepath: 'M1090_S15_B01_F07_0106.tif',
          version:,
          on_data: Proc
        )
      end
    end

    context 'when Faraday raises a client error' do
      before do
        allow(Preservation::Client.objects).to receive(:content).and_raise(Faraday::ClientError, 'uh oh')
        allow(Honeybadger).to receive(:notify)
        allow(Rails.logger).to receive(:error)
      end

      it 'closes the zip sink and continues' do
        get download_item_files_path(druid)
        expect(response).to have_http_status(:ok)
        expect(Rails.logger).to have_received(:error).twice
        expect(Honeybadger).to have_received(:notify).twice
        expect(fake_sink).to have_received(:close).twice
      end
    end
  end
end
