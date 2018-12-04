# frozen_string_literal: true

require 'spec_helper'

# Feature tests for the spreadsheet bulk uploads view.
RSpec.feature 'Bulk jobs view', js: true do
  before do
    sign_in create(:user), groups: ['sdr:administrator-role']
  end

  scenario 'the submit button exists' do
    visit apo_bulk_jobs_path('druid:hv992ry2431')
    expect(page).to have_link 'Submit new file ...', href: new_item_upload_path(item_id: 'druid:hv992ry2431')
  end

  scenario 'click submit button opens bulk upload form' do
    visit new_item_upload_path(item_id: 'druid:hv992ry2431')
    expect(page).to have_css('div#spreadsheet-upload-container form div#bulk-upload-form')
    expect(page).to have_css('input#spreadsheet_file')
  end

  scenario 'bulk upload form buttons are disabled upon first page visit' do
    visit new_item_upload_path(item_id: 'druid:hv992ry2431')
    expect(find('input#filetypes_1').disabled?).to be_truthy
    expect(find('input#filetypes_2').disabled?).to be_truthy
    expect(find('input#convert_only').disabled?).to be_truthy
    expect(find('input#note_text').disabled?).to be_truthy
    expect(find('button#spreadsheet_submit').disabled?).to be_truthy
    expect(find('button#spreadsheet_cancel').disabled?).to be_falsy
  end

  scenario 'selecting a file to upload and selecting one of the radio buttons enables the submit button' do
    visit new_item_upload_path(item_id: 'druid:hv992ry2431')
    expect(page).to have_css('#spreadsheet_file')
    expect(find('input#filetypes_1').disabled?).to be_truthy

    attach_file('spreadsheet_file', File.expand_path('../../fixtures/crowdsourcing_bridget_1.xlsx', __FILE__))

    # Manually trigger update event on file submit field, since Capybara/Poltergeist doesn't seem to do it
    page.execute_script("$('#spreadsheet_file').trigger('change')")

    expect(find('input#filetypes_1').disabled?).to be_falsy
    expect(page).to have_css('span#bulk-spreadsheet-warning', text: '')
    expect(find('button#spreadsheet_submit').disabled?).to be_truthy
    expect(find('input#filetypes_1').disabled?).to be_falsy
    choose('filetypes_1')
    expect(find('button#spreadsheet_submit').disabled?).to be_falsy
  end

  scenario 'uploading a file with an invalid extension displays a warning' do
    visit new_item_upload_path(item_id: 'druid:hv992ry2431')
    expect(page).to have_css('#spreadsheet_file')
    attach_file('spreadsheet_file', File.absolute_path(__FILE__))

    # Manually trigger update event on file submit field, since Capybara/Poltergeist doesn't seem to do it
    page.execute_script("$('#spreadsheet_file').trigger('change')")
    expect(page).to have_css('span#bulk-spreadsheet-warning', text: 'Note: Only spreadsheets or XML files are allowed. Please check your selected file.')
  end
end
