# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'application and dependency monitoring' do
  it '/status checks if Rails app is running' do
    visit '/status'
    expect(page.status_code).to eq 200
    expect(page).to have_text('Application is running')
  end

  context 'all checks' do
    before do
      stub_request(:get, Settings.spreadsheet_url)
        .to_return(status: 200, body: '', headers: {})

      stub_request(:get, "https://#{Settings.stacks.host}")
        .to_return(status: 200, body: '', headers: {})

      stub_request(:get, "#{Settings.modsulator_url.split('v1').first}v1/about")
        .to_return(status: 200, body: '', headers: {})

      stub_request(:get, Settings.normalizer_url)
        .to_return(status: 200, body: '', headers: {})
    end

    it 'checks dependencies' do
      visit '/status/all'
      expect(page).to have_text('dor_search_service_solr') # required check
    end
  end
end
