require 'spec_helper'

# Buttons are enabled in app/helpers/argo_helper#render_buttons.

feature 'Enable buttons' do
  before :each do
    admin_user # see spec_helper
  end

  scenario 'buttons are disabled by default that have check_url' do
    visit catalog_path 'druid:hj185vb7593'
    expect(page).to have_css 'a.disabled', text: 'Close Version'
    expect(page).to have_css 'a.disabled', text: 'Open for modification'
    expect(page).to have_css 'a.disabled', text: 'Republish'
    expect(page).to have_css 'a.disabled', text: 'Purge'
  end

  scenario 'buttons are enabled if their services return true', js: true do
    allow_any_instance_of(WorkflowServiceController).to receive(:check_if_can_close_version).and_return(true)
    allow_any_instance_of(WorkflowServiceController).to receive(:check_if_can_open_verison).and_return(true)
    allow_any_instance_of(WorkflowServiceController).to receive(:check_if_published).and_return(true)
    allow_any_instance_of(WorkflowServiceController).to receive(:check_if_submitted).and_return(true)
    visit catalog_path 'druid:hj185vb7593'
    expect(page).to_not have_css 'a.disabled', text: 'Close Version'
    expect(page).to_not have_css 'a.disabled', text: 'Open for modification'
    expect(page).to_not have_css 'a.disabled', text: 'Republish'
    expect(page).to_not have_css 'a.disabled', text: 'Purge'
  end
end
