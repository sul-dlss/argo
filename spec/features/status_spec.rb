# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'application and dependency monitoring' do
  it '/status checks if Rails app is running' do
    visit '/status'
    expect(page.status_code).to eq 200
    expect(page).to have_text('Application is running')
  end

  it 'RubydoraCheck at /status/active_fedora_conn runs' do
    visit '/status/active_fedora_conn'
    expect(page.status_code).to eq 200
    expect(page).to have_text('active_fedora_conn')
  end

  context 'all checks' do
    before do
      stub_request(:get, Settings.spreadsheet_url)
        .to_return(status: 200, body: '', headers: {})

      stub_request(:get, "https://#{Settings.stacks.host}")
        .to_return(status: 200, body: '', headers: {})

      stub_request(:get, Settings.stacks_file_url)
        .to_return(status: 200, body: '', headers: {})

      stub_request(:get, Settings.stacks_url)
        .to_return(status: 200, body: '', headers: {})

      stub_request(:get, Settings.modsulator_url)
        .to_return(status: 200, body: '', headers: {})

      stub_request(:get, Settings.normalizer_url)
        .to_return(status: 200, body: '', headers: {})
    end

    it 'checks dependencies' do
      visit '/status/all'
      expect(page).to have_text('dor_search_service_solr') # required check
      expect(page).to have_text('stacks_file_url') # non-crucial check
    end
  end
end
