# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Bulk DOI assignment' do
  let(:rendered) { Capybara::Node::Simple.new(response.body) }
  let(:user) { build(:user) }

  before { sign_in user, groups: ['sdr:administrator-role'] }

  describe 'GET /bulk_actions/doi_assignment_job/new' do
    it 'draws the form' do
      get '/bulk_actions/doi_assignment_job/new'

      expect(rendered).to have_css 'textarea[name="druids"]'
      expect(rendered).to have_css 'textarea[name="description"]'
      expect(rendered).to have_css 'input[type="checkbox"][value="true"][name="close_version"]'
    end
  end

  describe 'POST /bulk_actions/doi_assignment_job' do
    let(:druids) { 'druid:bc123df2345' }
    let(:params) { { 'druids' => druids, 'close_version' => 'true' } }

    it 'enqueues a job' do
      expect do
        post '/bulk_actions/doi_assignment_job', params:
      end.to have_enqueued_job(DoiAssignmentJob)
        .with(Integer, {
                groups: ["sunetid:#{user.login}", 'workgroup:sdr:administrator-role'],
                druids: [druids],
                close_version: 'true'
              })
      expect(response).to have_http_status(:see_other)
    end

    context 'when number of druids exceeds configured maximum' do
      let(:druids) { "druid:bc123df2345\n" * (Settings.datacite.batch_size + 1) }

      it 'does not enqueue a job' do
        expect do
          post '/bulk_actions/doi_assignment_job', params:
        end.not_to have_enqueued_job(DoiAssignmentJob)
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include('Maximum number of druids is 1,000')
      end
    end
  end
end
