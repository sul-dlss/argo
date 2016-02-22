require 'spec_helper'

feature 'Enable buttons' do
  before :each do
    @druid = 'druid:hj185vb7593'
    @current_user = double(
      :webauth_user,
      login: 'sunetid',
      logged_in?: true,
      permitted_apos: [],
      is_admin: true,
      roles: []
    )
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(@current_user)
  end
  scenario 'buttons are disabled by default that have check_url' do
    visit catalog_path @druid
    expect(page).to have_css 'a.disabled', text: 'Close Version'
    expect(page).to have_css 'a.disabled', text: 'Open for modification'
    expect(page).to have_css 'a.disabled', text: 'Republish'
    expect(page).to have_css 'a.disabled', text: 'Purge'
  end
  scenario 'buttons are enabled if their services return true', js: true do
    allow_any_instance_of(WorkflowServiceController).to receive(:check_if_can_close_version).and_return(true)
    allow_any_instance_of(WorkflowServiceController).to receive(:check_if_can_open_version).and_return(true)
    allow_any_instance_of(WorkflowServiceController).to receive(:check_if_published).and_return(true)
    allow_any_instance_of(WorkflowServiceController).to receive(:check_if_submitted).and_return(true)
    visit catalog_path @druid
    expect(page).to_not have_css 'a.disabled', text: 'Close Version'
    expect(page).to_not have_css 'a.disabled', text: 'Open for modification'
    expect(page).to_not have_css 'a.disabled', text: 'Republish'
    expect(page).to_not have_css 'a.disabled', text: 'Purge'
  end
end
