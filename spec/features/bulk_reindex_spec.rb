require 'spec_helper'

RSpec.feature 'Bulk Reindex of DOR Objects' do
  let(:current_user) { create(:user) }

  before(:each) do
    expect(current_user).to receive(:to_s).at_least(:once).and_return('name')
    allow_any_instance_of(BulkActionsController).to receive(:current_user).and_return(current_user)
  end

  scenario 'Creates a new job' do
    visit new_bulk_action_path
    choose 'bulk_action_action_type_remoteindexingjob'
    fill_in 'pids', with: 'druid:br481xz7820'
    click_button 'Submit'
    expect(page).to have_css 'h1', text: 'Bulk Actions'
    within 'table.table' do
      expect(page).to have_css 'td', text: 'RemoteIndexingJob'
      expect(page).to have_css 'td', text: BulkAction::FINISHED
    end
  end
end
