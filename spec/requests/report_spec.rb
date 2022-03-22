# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Reports from a search', type: :request do
  before do
    ResetSolr.reset_solr
    solr_conn.add(id: 'druid:xb482ww9999',
                  objectType_ssim: 'item',
                  obj_label_tesim: 'Report about stuff')
    solr_conn.commit
    sign_in user, groups: ['sdr:administrator-role']
  end

  let(:blacklight_config) { CatalogController.blacklight_config }
  let(:solr_conn) { blacklight_config.repository_class.new(blacklight_config).connection }

  let(:user) { create(:user) }

  describe 'The JSON endpoint' do
    before do
      allow(Report).to receive(:new).and_return(report)
    end

    let(:report) { instance_double(Report, num_found: 15, report_data: report_data) }
    let(:report_data) { Array.new(10, double) }

    context 'with the rows parameter' do
      let(:report_data) { Array.new(5, double) }

      it 'returns json' do
        get '/report/data.json?rows=5'
        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)
        expect(Report).to have_received(:new).with(hash_including(per_page: 5), Hash)
        expect(data['rows'].length).to eq 5
      end
    end

    it 'defaults to 10 rows per page, rather than defaulting to 0 and generating an exception when the number of pages is infinity when no row count is passed in' do
      get '/report/data.json'
      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body)
      expect(data['rows'].length).to eq(10)
    end

    context 'with user custom entered dates' do
      let(:report_data) { Array.new(5, double) }

      it 'returns data for custom date searches' do
        params = { f: { modified_latest_dttsi: ['[2015-10-01T00:00:00.000Z TO 2050-10-07T23:59:59.000Z]'] }, rows: 5 }
        get '/report/data.json', params: params

        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)
        expect(Report).to have_received(:new)
          .with(hash_including('f' => { 'modified_latest_dttsi' => ['[2015-10-01T00:00:00.000Z TO 2050-10-07T23:59:59.000Z]'] }, per_page: 5), Hash)

        expect(data['rows'].length).to eq(5)
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
      get '/report/download?fields=druid,purl,source_id_ssim,tag_ssim'

      expect(response).to have_http_status(:ok)
      data = CSV.parse(response.body)
      expect(data.first).to eq(['Druid', 'Purl', 'Source Id', 'Tags'])
      expect(Report).to have_received(:new).with(ActionController::Parameters, %w[druid purl source_id_ssim tag_ssim], Hash)
      expect(data.length).to be > 1
      expect(data[1].first).to eq('ab123gg7777') # first data row starts with druid
    end
  end
end
