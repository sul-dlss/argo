# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Reports from a search' do
  before do
    sign_in user, groups: ['sdr:administrator-role']
  end

  let(:blacklight_config) { CatalogController.blacklight_config }
  let(:solr_conn) { blacklight_config.repository_class.new(blacklight_config).connection }

  let(:user) { create(:user) }

  describe 'The JSON endpoint' do
    before do
      allow(Report).to receive(:new).and_return(report)
    end

    let(:report) { instance_double(Report, num_found: 15, report_data:) }
    let(:report_data) { Array.new(100, double) }

    context 'with the per_page parameter' do
      let(:report_data) { Array.new(5, double) }

      it 'returns json' do
        get '/report/data.json?per_page=5'
        expect(response).to have_http_status(:ok)
        data = response.parsed_body
        expect(Report).to have_received(:new).with(hash_including(per_page: 5), anything)
        expect(data['data'].length).to eq(5)
      end
    end

    it 'defaults to 100 rows per page, rather than defaulting to 0 and generating an exception when the number of pages is infinity when no row count is passed in' do
      get '/report/data.json'
      expect(response).to have_http_status(:ok)
      data = response.parsed_body
      expect(data['data'].length).to eq(100)
    end

    context 'with user custom entered dates' do
      let(:report_data) { Array.new(5, double) }

      it 'returns data for custom date searches' do
        params = { f: { modified_latest_dttsi: ['[2015-10-01T00:00:00.000Z TO 2050-10-07T23:59:59.000Z]'] },
                   per_page: 5,
                   controller: 'report',
                   action: 'data',
                   format: 'json',
                   page: '1' }
        get('/report/data.json', params:)

        expect(response).to have_http_status(:ok)
        data = response.parsed_body
        expect(Report).to have_received(:new).with(ActionController::Parameters.new(params), anything)
        expect(data['data'].length).to eq(5)
      end
    end
  end

  describe 'The CSV endpoint' do
    before do
      allow(Report).to receive(:new).and_return(report)
    end

    let(:report) { instance_double(Report, to_csv: csv) }
    let(:csv) { "Druid,Purl,Source Id,Tags\nab123gg7777\nqh056qq6868" }

    it 'downloads valid CSV data for specific fields' do
      get '/report/download?fields=druid,purl,source_id_ssi,tag_ssim'

      expect(response).to have_http_status(:ok)
      data = CSV.parse(response.body)
      expect(data.first).to eq(['Druid', 'Purl', 'Source Id', 'Tags'])
      expect(Report).to have_received(:new).with(ActionController::Parameters, Hash)
      expect(data.length).to be > 1
      expect(data[1].first).to eq('ab123gg7777') # first data row starts with druid
    end
  end
end
