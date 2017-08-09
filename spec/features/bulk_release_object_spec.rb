require 'spec_helper'

RSpec.feature 'Bulk Object Release' do
  let(:current_user) { create(:user) }
  before(:each) do
    expect(current_user).to receive(:to_s).at_least(:once).and_return('name')
    # Needed because we are accessing multiple instances of BulkActionsController
    allow_any_instance_of(BulkActionsController).to receive(:current_user)
      .and_return(current_user)
  end
  scenario 'Creates a new jobs' do
    visit new_bulk_action_path
    choose 'bulk_action_action_type_releaseobjectjob'
    fill_in 'pids', with: 'druid:br481xz7820'
    click_button 'Submit'
    expect(page).to have_css 'h1', text: 'Bulk Actions'
    within 'table.table' do
      expect(page).to have_css 'td', text: 'ReleaseObjectJob'
      expect(page).to have_css 'td', text: BulkAction::FINISHED
    end
  end
end
