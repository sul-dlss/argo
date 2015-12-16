require 'spec_helper'

RSpec.feature 'Workflow Service Creation' do
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
  before do
    allow_any_instance_of(ItemsController).to receive(:current_user)
      .and_return(current_user)
    allow_any_instance_of(CatalogController).to receive(:current_user)
      .and_return(current_user)
  end
  scenario 'redirect and display on show page' do
    visit add_workflow_item_path 'druid:hj185vb7593'
    click_button 'Add'
    within '.flash_messages' do
      expect(page).to have_css '.alert.alert-info', text: 'Added accessionWF'
    end
    expect(page).to have_css 'tr td a', text: 'accessionWF'
  end
end
