# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Download item files' do
  let(:pid) { cocina_model.externalIdentifier }
  let(:cocina_model) { Cocina::Models.build(cocina_params.stringify_keys) }
  let(:cocina_params) do
    {
      "type": 'http://cocina.sul.stanford.edu/models/image.jsonld',
      "externalIdentifier": 'druid:rn653dy9317',
      "label": 'M1090_S15_B01_F07_0106',
      "version": 4,
      "access": {
        "access": 'location-based',
        "copyright": '© The Estate of R. Buckminster Fuller.',
        "download": 'location-based',
        "readLocation": 'spec'
      },
      "administrative": {
        "hasAdminPolicy": 'druid:rd845kr7465'
      },
      "identification": {
        "sourceId": 'fuller:M1090_S15_B01_F07_0106'
      },
      "structural": {
        "contains": [
          {
            "type": 'http://cocina.sul.stanford.edu/models/fileset.jsonld',
            "externalIdentifier": 'rn653dy9317_106',
            "label": 'M1090_S15_B01_F07_0106',
            "version": 4,
            "structural": {
              "contains": [
                {
                  "type": 'http://cocina.sul.stanford.edu/models/file.jsonld',
                  "externalIdentifier": 'druid:rn653dy9317/M1090_S15_B01_F07_0106.jp2',
                  "label": 'M1090_S15_B01_F07_0106.jp2',
                  "filename": 'M1090_S15_B01_F07_0106.jp2',
                  "size": 3_305_991,
                  "version": 4,
                  "hasMimeType": 'image/jp2',
                  "hasMessageDigests": [
                    {
                      "type": 'sha1',
                      "digest": 'fd28e74b3139b04a0e5c5c3d3263598f629f8967'
                    },
                    {
                      "type": 'md5',
                      "digest": '244cbb3960407f59ac77a916870e0502'
                    }
                  ],
                  "access": {
                    "access": 'world',
                    "download": 'world'
                  },
                  "administrative": {
                    "sdrPreserve": true,
                    "shelve": true
                  },
                  "presentation": {
                    "height": 3426,
                    "width": 5102
                  }
                },
                {
                  "type": 'http://cocina.sul.stanford.edu/models/file.jsonld',
                  "externalIdentifier": 'druid:rn653dy9317/M1090_S15_B01_F07_0106.tif',
                  "label": 'M1090_S15_B01_F07_0106.tif',
                  "filename": 'M1090_S15_B01_F07_0106.tif',
                  "size": 52_467_428,
                  "version": 4,
                  "hasMimeType": 'image/tiff',
                  "hasMessageDigests": [
                    {
                      "type": 'sha1',
                      "digest": 'cf336c4f714b180a09bbfefde159d689e1d517bd'
                    },
                    {
                      "type": 'md5',
                      "digest": '56978088366e66f87d4d5a531f2fea04'
                    }
                  ],
                  "access": {
                    "access": 'dark',
                    "download": 'none'
                  },
                  "administrative": {
                    "sdrPreserve": true,
                    "shelve": false
                  },
                  "presentation": {
                    "height": 3426,
                    "width": 5102
                  }
                }
              ]
            }
          }
        ],
        "isMemberOf": [
          'druid:rh056sr3313'
        ],
        "hasAgreement": 'druid:xf765cv5573'
      }
    }
  end
  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model) }
  let(:bare_druid) { pid.delete_prefix('druid:') }
  let(:user) { create(:user) }

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    sign_in user
  end

  context 'when unauthorized' do
    it 'returns HTTP forbidden' do
      get download_item_files_path(pid)
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
    end

    it 'sets content-disposition header' do
      get download_item_files_path(pid)
      expect(response.headers.to_h).to include(
        'Content-Disposition' => "attachment; filename=#{bare_druid}.zip",
        'Content-Type' => 'application/zip'
      )
    end

    it 'zips files set for preservation' do
      get download_item_files_path(pid)
      expect(fake_zip).to have_received(:write_deflated_file).with('M1090_S15_B01_F07_0106.jp2').once
      expect(fake_zip).to have_received(:write_deflated_file).with('M1090_S15_B01_F07_0106.tif').once
      expect(Preservation::Client.objects).to have_received(:content).with(
        druid: pid,
        filepath: 'M1090_S15_B01_F07_0106.jp2',
        version: 4,
        on_data: Proc
      )
      expect(Preservation::Client.objects).to have_received(:content).with(
        druid: pid,
        filepath: 'M1090_S15_B01_F07_0106.tif',
        version: 4,
        on_data: Proc
      )
    end

    context 'when Faraday raises a client error' do
      before do
        allow(Preservation::Client.objects).to receive(:content).and_raise(Faraday::ClientError, 'uh oh')
        allow(Honeybadger).to receive(:notify)
        allow(Rails.logger).to receive(:error)
      end

      it 'closes the zip sink and raises' do
        get download_item_files_path(pid)
        expect(response).to have_http_status(:internal_server_error)
        expect(response.body).to eq("Could not zip M1090_S15_B01_F07_0106.jp2 (#{pid}) for download: uh oh")
        expect(Rails.logger).to have_received(:error).twice
        expect(Honeybadger).to have_received(:notify).twice
        expect(fake_sink).to have_received(:close).twice
      end
    end
  end
end
