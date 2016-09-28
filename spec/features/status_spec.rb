require 'spec_helper'

RSpec.feature 'application and dependency monitoring' do
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
  it '/status/all checks if required dependencies are ok and also shows non-crucial dependencies' do
    visit '/status/all'
    expect(page).to have_text('dor_search_service_solr') # required check
    expect(page).to have_text('stacks_file_url') # non-crucial check
  end
end
