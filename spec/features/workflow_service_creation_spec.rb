require 'spec_helper'

feature 'Workflow Service Creation' do
  let(:current_user) do
    double(
      :webauth_user,
      login: 'sunetid',
      logged_in?: true,
      permitted_apos: [],
      is_admin: true,
      roles: []
    )
  end
  before :each do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(current_user)
    @druid = 'druid:qq613vj0238' # a fixture Dor::Item record
  end

  scenario 'redirect and display on show page - with JS', js: true do
    visit add_workflow_item_path(@druid)
    expect(page).to have_content('Add workflow')
    expect(page).to have_button('Add')
    find('#wf').find(:option, 'accessionWF').select_option
    find('#add_wf_button').trigger('click')
    within '.flash_messages' do
      expect(page).to have_css '.alert.alert-info', text: 'Added accessionWF'
    end
    expect(page).to have_css 'tr td a', text: 'accessionWF'
  end
end
