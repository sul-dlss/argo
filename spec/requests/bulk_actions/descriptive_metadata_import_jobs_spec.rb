# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Bulk descriptive metadata import', type: :request do
  let(:rendered) do
    Capybara::Node::Simple.new(response.body)
  end

  describe 'GET #new' do
    before do
      sign_in build(:user), groups: ['sdr:administrator-role']
    end

    it 'draws the form' do
      get '/bulk_actions/descriptive_metadata_import_job/new'

      expect(rendered).to have_css 'textarea[name="description"]'
      expect(rendered).to have_css 'input[type="file"][name="csv_file"]'
    end
  end

  describe 'create' do
    let(:user) { build(:user) }

    before do
      sign_in user, groups: ['sdr:administrator-role']
    end

    it 'creates a job' do
      params = { 'csv_file' => fixture_file_upload('bulk_upload_descriptive.csv', 'text/csv') }

      expect { post '/bulk_actions/descriptive_metadata_import_job', params: }.to have_enqueued_job(DescriptiveMetadataImportJob)
        .with(Integer, {
                groups: ["sunetid:#{user.login}", 'workgroup:sdr:administrator-role'],
                csv_file: String
              })
      expect(response).to have_http_status(:see_other)
    end

    context 'when invalid csv' do
      it 'does not create the job' do
        params = { 'csv_file' => fixture_file_upload('invalid_bulk_upload_descriptive.csv', 'text/csv') }

        expect { post '/bulk_actions/descriptive_metadata_import_job', params: }.not_to have_enqueued_job(DescriptiveMetadataImportJob)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to match('Column header invalid: xsource_id')
      end
    end
  end
end
