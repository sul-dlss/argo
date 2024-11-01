# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Bulk Object Release', :js do
  let(:current_user) { create(:user) }

  before do
    sign_in current_user
  end

  it 'Creates new jobs' do
    visit new_bulk_action_path
    select 'Manage release'
    fill_in 'Druids to perform bulk action on', with: 'druid:ab123gg7777'
    click_button 'Submit'
    expect(page).to have_css 'h1', text: 'Bulk Actions'
    perform_enqueued_jobs
    reload_page_until_timeout do
      page.has_css?('td', text: 'ReleaseObjectJob') &&
        page.has_css?('td', text: 'Completed')
    end
  end
end
