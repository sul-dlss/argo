# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'BulkActions::GoverningApoJobs' do
  let(:rendered) do
    Capybara::Node::Simple.new(response.body)
  end

  describe 'GET #new' do
    before do
      sign_in build(:user), groups: ['sdr:administrator-role']
      allow(SearchService).to receive(:query).and_return(solr_response)
    end

    let(:solr_response) do
      {
        'response' => {
          'docs' => [
            { 'id' => 'druid:123', 'display_title_ss' => 'APO 1' },
            { 'id' => 'druid:234', 'display_title_ss' => 'APO 2' }
          ]
        }
      }
    end

    it 'draws the form' do
      get '/bulk_actions/governing_apo_job/new'

      expect(rendered).to have_css 'textarea[name="druids"]'
      expect(rendered).to have_css 'textarea[name="description"]'
      expect(rendered).to have_css 'select[name="new_apo_id"] option[value="druid:234"]'
    end
  end
end
