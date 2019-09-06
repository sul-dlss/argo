# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Bulk Object Release' do
  let(:current_user) { create(:user) }

  before do
    sign_in current_user
  end

  it 'Creates a new jobs' do
    visit new_bulk_action_path
    select 'Manage release'
    fill_in 'pids', with: 'druid:br481xz7820'
    click_button 'Submit'
    expect(page).to have_css 'h1', text: 'Bulk Actions'
    within 'table.table' do
      expect(page).to have_css 'td', text: 'ReleaseObjectJob'
      expect(page).to have_css 'td', text: 'Scheduled Action'
    end
  end
end
