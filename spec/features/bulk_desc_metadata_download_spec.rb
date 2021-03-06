# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Bulk Descriptive Metadata Download' do
  let(:current_user) { create(:user) }

  before do
    sign_in current_user
  end

  it 'New page has a populate druids div with last search' do
    visit search_catalog_path q: 'stanford'
    click_link 'Bulk Actions'
    expect(page).to have_css 'h1', text: 'Bulk Actions'
    click_link 'New Bulk Action'
    expect(page).to have_css 'h1', text: 'New Bulk Action'
    expect(page).to have_css 'button[data-populate-druids="/catalog?action=index&' \
      'controller=catalog&pids_only=true&q=stanford"]'
  end

  it 'Creates a new jobs' do
    visit new_bulk_action_path
    select 'Download descriptive metadata'

    fill_in 'pids', with: 'druid:ab123gg7777'
    click_button 'Submit'
    expect(page).to have_css 'h1', text: 'Bulk Actions'
    reload_page_until_timeout do
      page.has_css?('td', text: 'DescmetadataDownloadJob') &&
        page.has_css?('td', text: 'Completed')
    end
  end
end
