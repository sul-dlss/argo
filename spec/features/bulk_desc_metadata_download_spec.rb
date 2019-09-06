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
    expect(page).to have_css 'a[data-populate-druids="/catalog?action=index&' \
      'controller=catalog&pids_only=true&q=stanford"]'
  end
  it 'Populate druids from last search' do
    pending 'not implemented spec due to js testing restrictions'
    fail
  end
  it 'Creates a new jobs' do
    visit new_bulk_action_path
    choose 'bulk_action_action_type_descmetadatadownloadjob'
    fill_in 'pids', with: 'druid:br481xz7820'
    click_button 'Submit'
    expect(page).to have_css 'h1', text: 'Bulk Actions'
    within 'table.table' do
      expect(page).to have_css 'td', text: 'DescmetadataDownloadJob'
      expect(page).to have_css 'td', text: 'Scheduled Action'
    end
  end
end
