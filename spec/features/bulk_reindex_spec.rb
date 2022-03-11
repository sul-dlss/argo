# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Bulk Reindex of DOR Objects', js: true do
  let(:current_user) { create(:user) }

  before do
    sign_in current_user
    allow(RemoteIndexingJob).to receive(:perform_later)
  end

  it 'Creates a new job' do
    visit new_bulk_action_path
    select 'Reindex'
    fill_in 'Druids to perform bulk action on', with: 'druid:ab123gg7777'
    click_button 'Submit'
    expect(page).to have_css 'h1', text: 'Bulk Actions'
    page.has_css?('td', text: 'RemoteIndexingJob') &&
      page.has_css?('td', text: 'Scheduled Action')
    expect(RemoteIndexingJob).to have_received(:perform_later)
  end
end
