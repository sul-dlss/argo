require 'spec_helper'

feature 'Workflow Service Creation' do
  before :each do
    admin_user # see spec_helper
  end
  scenario 'redirect and display on show page' do
    visit add_workflow_item_path 'druid:qq613vj0238'
    click_button 'Add'
    within '.flash_messages' do
      expect(page).to have_css '.alert.alert-info', text: 'Added accessionWF'
    end
    expect(page).to have_css 'tr td a', text: 'accessionWF'
  end
end
