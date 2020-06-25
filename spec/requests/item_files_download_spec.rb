# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Download item files' do
  let(:bare_druid) { 'rn653dy9317' }
  let(:pid) { "druid:#{bare_druid}" }
  let(:user) { create(:user) }

  before do
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
        version: 1,
        on_data: Proc
      )
      expect(Preservation::Client.objects).to have_received(:content).with(
        druid: pid,
        filepath: 'M1090_S15_B01_F07_0106.tif',
        version: 1,
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
