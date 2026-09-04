# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'BulkActions::RegisterDruidJobs' do
  describe 'create' do
    let(:user) { build(:user) }

    before do
      sign_in user, groups: ['sdr:administrator-role']
    end

    it 'creates a job' do
      params = { 'csv_file' => fixture_file_upload('register_druids.csv', 'text/csv') }

      expect { post '/bulk_actions/register_druid_job', params: }.to have_enqueued_job(RegisterDruidsJob)
        .with(Integer, {
                groups: ["sunetid:#{user.login}", 'workgroup:sdr:administrator-role'],
                csv_file: String
              })
      expect(response).to have_http_status(:see_other)
    end

    context 'when the CSV has a label column instead of a title column' do
      it 'does not create the job and calls out the label column' do
        params = { 'csv_file' => fixture_file_upload('register_druids_missing_title.csv', 'text/csv') }

        expect { post '/bulk_actions/register_druid_job', params: }.not_to have_enqueued_job(RegisterDruidsJob)
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to match('column, which is not valid')
        expect(response.body).to match('missing title. For each row, one of these must be provided: title')
      end
    end

    context 'when the CSV has a label column alongside a title column' do
      it 'does not create the job' do
        params = { 'csv_file' => fixture_file_upload('register_druids_label_and_title.csv', 'text/csv') }

        expect { post '/bulk_actions/register_druid_job', params: }.not_to have_enqueued_job(RegisterDruidsJob)
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to match('column, which is not valid')
        expect(response.body).not_to match('missing title')
      end
    end
  end
end
