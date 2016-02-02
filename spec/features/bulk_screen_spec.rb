require 'spec_helper'

# Feature/view tests for the (old) bulk actions view.
feature 'Bulk actions view', js: true do
  before :each do
    admin_user # see spec_helper
  end

  scenario 'basic page renders ok', :focus => true do
    visit report_bulk_path

    expect(page).to have_css('h1', 'Bulk update operations')
    expect(find(:xpath, "//span[@class='bulk_button'][text()='Get druids from search'][not(@disabled)]")).to be_truthy
    expect(find(:xpath, "//span[@class='bulk_button'][text()='Paste a druid list'][not(@disabled)]")).to be_truthy

    find(:xpath, "//span[@class='bulk_button'][text()='Get druids from search'][not(@disabled)]").click

    expect(find_button('Prepare objects')).to be_truthy
    expect(page).to have_button('Prepare objects', disabled: false)
    expect(page).to have_button('Refresh MODS', disabled: false)
    expect(page).to have_button('Set source Id', disabled: false)
    expect(page).to have_button('Set object rights', disabled: false)
    expect(page).to have_button('Set content type', disabled: false)
    expect(page).to have_button('Set collection', disabled: false)
    expect(page).to have_button('Add collection', disabled: false)
    expect(page).to have_button('Apply APO defaults', disabled: false)
    expect(page).to have_button('Add a workflow', disabled: false)
    expect(page).to have_button('Close versions', disabled: false)
    expect(page).to have_button('Reindex', disabled: false)
    expect(page).to have_button('Republish', disabled: false)
    expect(page).to have_button('Tags', disabled: false)
    expect(page).to have_button('Purge', disabled: false)
  end
end
