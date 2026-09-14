# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'BulkActions::ManageEmbargoJobs' do
  let(:rendered) do
    Capybara::Node::Simple.new(response.body)
  end

  describe 'GET #new' do
    before do
      sign_in build(:user), groups: ['sdr:administrator-role']
    end

    it 'draws the form' do
      get '/bulk_actions/manage_embargo_job/new'

      expect(rendered).to have_css 'textarea[name="description"]'
      expect(rendered).to have_css 'input[type="file"][name="csv_file"]'
    end
  end

  describe 'POST #create' do
    let(:user) { build(:user) }

    before do
      sign_in user, groups: ['sdr:administrator-role']
    end

    it 'creates a job' do
      params = { 'csv_file' => fixture_file_upload('manage_embargo.csv', 'text/csv') }

      expect { post '/bulk_actions/manage_embargo_job', params: }.to have_enqueued_job(ManageEmbargoesJob)
        .with(Integer, {
                groups: ["sunetid:#{user.login}", 'workgroup:sdr:administrator-role'],
                csv_file: String,
                close_version: nil
              })
      expect(response).to have_http_status(:see_other)
    end

    context 'when the csv_file is missing the view and download headers' do
      it 'does not create the job and calls out the missing headers' do
        params = { 'csv_file' => fixture_file_upload('manage_embargo_missing_view_download.csv', 'text/csv') }

        expect { post '/bulk_actions/manage_embargo_job', params: }.not_to have_enqueued_job(ManageEmbargoesJob)
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include('missing headers: view, download')
      end
    end

    context 'when the csv has location-based access but no location column' do
      it 'does not create the job and calls out the missing location header' do
        params = { 'csv_file' => fixture_file_upload('manage_embargo_missing_location.csv', 'text/csv') }

        expect { post '/bulk_actions/manage_embargo_job', params: }.not_to have_enqueued_job(ManageEmbargoesJob)
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include('is missing the location header (required when view or download access is location-based)')
      end
    end
  end
end
