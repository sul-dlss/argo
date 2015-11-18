require 'spec_helper'

# Feature tests for the spreadsheet bulk uploads view.
feature 'Bulk jobs view', js: true do

  before :each do
    @current_user = double(
      :webauth_user,
      login: 'sunetid',
      logged_in?: true,
      permitted_apos: [],
      is_admin: true
    )
    allow(@current_user).to receive(:roles).and_return([])  # necessary to determine if current user has right permissions
    allow_any_instance_of(ApplicationController).to receive(:current_user).
                                                    and_return(@current_user)
  end

  scenario 'the submit button exists' do
    visit bulk_jobs_index_path('druid:hv992ry2431')
    expect(page).to have_link('Submit new file ...', href: '/catalog/druid:hv992ry2431/bulk_upload_form')
  end

  scenario 'click submit button opens bulk upload form' do
    visit bulk_upload_form_path(id: 'druid:hv992ry2431')
    expect(page).to have_css('div#spreadsheet-upload-container form div#bulk-upload-form')
    expect(page).to have_css('input#spreadsheet_file')
  end

  scenario 'bulk upload form buttons are disabled upon first page visit' do
    visit bulk_upload_form_path(id: 'druid:hv992ry2431')
    expect(find('input#filetypes_1').disabled?).to be_truthy
    expect(find('input#filetypes_2').disabled?).to be_truthy
    expect(find('input#convert_only').disabled?).to be_truthy
    expect(find('input#note_text').disabled?).to be_truthy
    expect(find('button#spreadsheet_submit').disabled?).to be_truthy
    expect(find('button#spreadsheet_cancel').disabled?).to be_falsy
  end

  scenario 'selecting a file to upload and selecting one of the radio buttons enables the submit button' do
    visit bulk_upload_form_path(id: 'druid:hv992ry2431')
    expect(page).to have_css('#spreadsheet_file')
    expect(find('input#filetypes_1').disabled?).to be_truthy

    attach_file('spreadsheet_file', File.expand_path('../../fixtures/crowdsourcing_bridget_1.xlsx', __FILE__))

    # Manually trigger update event on file submit field, since Capybara/Poltergeist doesn't seem to do it
    page.execute_script("$('#spreadsheet_file').trigger('change')")

    expect(find('input#filetypes_1').disabled?).to be_falsy
    expect(page).to have_css('span#bulk-spreadsheet-warning', text: "")
    expect(find('button#spreadsheet_submit').disabled?).to be_truthy
    expect(find('input#filetypes_1').disabled?).to be_falsy
    choose('filetypes_1')
    expect(find('button#spreadsheet_submit').disabled?).to be_falsy
  end

  scenario 'uploading a file with an invalid extension displays a warning' do
    visit bulk_upload_form_path(id: 'druid:hv992ry2431')
    expect(page).to have_css('#spreadsheet_file')
    attach_file('spreadsheet_file', File.absolute_path(__FILE__))

    # Manually trigger update event on file submit field, since Capybara/Poltergeist doesn't seem to do it
    page.execute_script("$('#spreadsheet_file').trigger('change')")
    expect(page).to have_css('span#bulk-spreadsheet-warning', text: "Note: Only spreadsheets or XML files are allowed. Please check your selected file.")
  end
end
