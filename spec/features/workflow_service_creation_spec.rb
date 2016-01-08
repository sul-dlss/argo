require 'spec_helper'

feature 'Workflow Service Creation' do
  let(:druid) { 'qq613vj0238' } # a fixture Dor::Item record
  let(:pid) { DruidTools::Druid.new(druid).druid }
  # This spec doesn't work with a mock Dor::Item
  # let(:item) { instantiate_fixture(druid, Dor::Item) }
  # allow(Dor).to receive(:find).with(pid).and_return(item)

  before :each do
    admin_user # see spec_helper
  end

  scenario 'redirect and display on show page - with JS', js: true do
    visit add_workflow_item_path(pid)
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
