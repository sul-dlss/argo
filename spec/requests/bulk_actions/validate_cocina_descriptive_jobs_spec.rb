# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Bulk validate cocina descriptive' do
  let(:rendered) do
    Capybara::Node::Simple.new(response.body)
  end

  describe 'GET #new' do
    before do
      sign_in build(:user), groups: ['sdr:administrator-role']
    end

    it 'draws the form' do
      get '/bulk_actions/validate_cocina_descriptive_job/new'

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

      expect do
        post '/bulk_actions/validate_cocina_descriptive_job', params:
      end.to have_enqueued_job(ValidateCocinaDescriptiveJob)
        .with(Integer, { csv_file: String })
      expect(response).to have_http_status(:see_other)
    end

    context 'when duplicate columns in csv' do
      it 'does not create the job' do
        params = { 'csv_file' => fixture_file_upload('invalid_bulk_upload_duplicate_fields.csv', 'text/csv') }

        expect do
          post '/bulk_actions/validate_cocina_descriptive_job', params:
        end.not_to have_enqueued_job(ValidateCocinaDescriptiveJob)
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to match('uplicate column headers: The header adminMetadata.contributor1.name1.code should occur only once.')
      end
    end

    context 'when invalid csv' do
      it 'does not create the job' do
        params = { 'csv_file' => fixture_file_upload('invalid_bulk_upload_descriptive.csv', 'text/csv') }

        expect do
          post '/bulk_actions/validate_cocina_descriptive_job', params:
        end.not_to have_enqueued_job(ValidateCocinaDescriptiveJob)
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to match('Column header invalid: xsource_id')
      end
    end

    context 'when invalid bytes in csv' do
      it 'does not create the job and displays an error' do
        params = { 'csv_file' => fixture_file_upload('invalid_bulk_upload_nonutf8.csv', 'text/csv') }

        expect do
          post '/bulk_actions/validate_cocina_descriptive_job', params:
        end.not_to have_enqueued_job(ValidateCocinaDescriptiveJob)
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to match('Error starting bulk action: Invalid byte sequence')
      end
    end
  end
end
