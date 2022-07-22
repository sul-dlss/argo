# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Item registration page', js: true do
  let(:user) { create(:user) }

  before do
    sign_in user, groups: ['sdr:administrator-role', 'dlss:developers']
  end

  context 'successful registration' do
    let(:bulk_action) { instance_double(BulkAction, save: true, enqueue_job: true) }

    before do
      allow(BulkAction).to receive(:new).and_return(bulk_action)
    end

    it 'starts bulk action' do
      visit registration_path
      select '[Internal System Objects]', from: 'Admin Policy' # "uber APO"
      select 'registrationWF', from: 'Initial Workflow'
      select 'book', from: 'Content Type'
      select 'left-to-right', from: 'Viewing Direction'
      select 'Stanford', from: 'View access'
      select 'Stanford', from: 'Download access'

      fill_in 'Project Name', with: 'X-Files'
      fill_in 'Tags', with: 'i : believe'

      click_button 'Upload CSV'

      attach_file 'Upload a CSV file', file_fixture('item_registration.csv')

      click_button 'Register'

      expect(page).to have_content 'Register druids job was successfully created.'
      expect(page).to have_content 'Bulk Actions'

      expect(BulkAction).to have_received(:new).with(user:, action_type: 'RegisterDruidsJob')
      expect(bulk_action).to have_received(:save)
      expect(bulk_action).to have_received(:enqueue_job).with(
        {
          administrative_policy_object: 'druid:hv992ry2431',
          content_type: 'https://cocina.sul.stanford.edu/models/book',
          csv_file: "source_id,catkey,barcode,label\nfoo:123,,,My new object\n",
          groups:
           ["sunetid:#{user.login}",
            'workgroup:sdr:administrator-role',
            'workgroup:dlss:developers'],
          initial_workflow: 'registrationWF',
          project_name: 'X-Files',
          reading_order: 'left-to-right',
          rights_download: 'stanford',
          rights_view: 'stanford',
          tags: ['i : believe', "Registered By : #{user.login}"]
        }
      )
    end
  end

  context 'registration fails validation' do
    it 'reports error' do
      visit registration_path
      select '[Internal System Objects]', from: 'Admin Policy' # "uber APO"
      select 'registrationWF', from: 'Initial Workflow'
      select 'book', from: 'Content Type'
      select 'left-to-right', from: 'Viewing Direction'
      select 'Stanford', from: 'View access'
      select 'Stanford', from: 'Download access'

      fill_in 'Project Name', with: 'X-Files'
      fill_in 'Tags', with: 'i : believe'

      click_button 'Upload CSV'

      attach_file 'Upload a CSV file', file_fixture('catkey_and_barcode.csv')

      click_button 'Register'

      expect(page).to have_content 'Register DOR Items'
      expect(page).to have_content 'Csv file missing headers: source_id.'
    end
  end

  context 'invalid CSV' do
    it 'reports error' do
      visit registration_path
      select '[Internal System Objects]', from: 'Admin Policy' # "uber APO"
      select 'registrationWF', from: 'Initial Workflow'
      select 'book', from: 'Content Type'
      select 'left-to-right', from: 'Viewing Direction'
      select 'Stanford', from: 'View access'
      select 'Stanford', from: 'Download access'

      fill_in 'Project Name', with: 'X-Files'
      fill_in 'Tags', with: 'i : believe'

      click_button 'Upload CSV'

      attach_file 'Upload a CSV file', file_fixture('character-test.csv')

      click_button 'Register'

      expect(page).to have_content 'Register DOR Items'
      expect(page).to have_content 'Csv file is invalid'
    end
  end
end
