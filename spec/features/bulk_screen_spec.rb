# frozen_string_literal: true

require 'rails_helper'

# Feature/view tests for the (old) bulk actions view.
RSpec.describe 'Bulk actions view', js: true do
  before do
    sign_in create(:user), groups: ['sdr:administrator-role']
  end

  it 'basic page renders ok' do
    visit report_bulk_path

    expect(page).to have_css('h1', text: 'Bulk update operations')
    expect(find(:xpath, "//span[@class='bulk_button'][text()='Get druids from search'][not(@disabled)]")).to be_truthy
    expect(find(:xpath, "//span[@class='bulk_button'][text()='Paste a druid list'][not(@disabled)]")).to be_truthy

    find(:xpath, "//span[@class='bulk_button'][text()='Get druids from search'][not(@disabled)]").click

    expect(page).to have_button('Refresh MODS', disabled: false)
    expect(page).to have_button('Set source Id', disabled: false)
    expect(page).to have_button('Set object rights', disabled: false)
    expect(page).to have_button('Set content type', disabled: false)
    expect(page).to have_button('Set collection', disabled: false)
    expect(page).to have_button('Apply APO defaults', disabled: false)
    expect(page).to have_button('Add a workflow', disabled: false)
    expect(page).to have_button('Close versions', disabled: false)
    expect(page).to have_button('Republish', disabled: false)
    expect(page).to have_button('Tags', disabled: false)
    expect(page).to have_button('Purge', disabled: false)
  end
end
