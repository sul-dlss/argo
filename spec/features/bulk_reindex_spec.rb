# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Bulk Reindex of DOR Objects' do
  let(:current_user) { create(:user) }

  before do
    sign_in current_user
  end

  it 'Creates a new job' do
    visit new_bulk_action_path
    select 'Reindex'
    fill_in 'pids', with: 'druid:ab123gg7777'
    click_button 'Submit'
    expect(page).to have_css 'h1', text: 'Bulk Actions'
    reload_page_until_timeout do
      page.has_css?('td', text: 'RemoteIndexingJob') &&
        page.has_css?('td', text: 'Processing')
    end
  end
end
