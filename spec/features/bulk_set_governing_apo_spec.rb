# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Bulk Update of Governing APO', js: true do
  let(:current_user) { create(:user) }

  before do
    sign_in current_user
    allow_any_instance_of(RegistrationHelper).to receive(:apo_list).and_return(['APO 1', 'APO 2', 'APO 3'])
  end

  it 'Creates a new job' do
    visit new_bulk_action_path
    select 'Update governing APO'
    select 'APO 2'
    fill_in 'Druids to perform bulk action on', with: 'druid:ab123gg7777'
    click_button 'Submit'

    expect(page).to have_css 'h1', text: 'Bulk Actions'
    reload_page_until_timeout do
      page.has_css?('td', text: 'SetGoverningApoJob') &&
        page.has_css?('td', text: 'Completed')
    end
  end
end
