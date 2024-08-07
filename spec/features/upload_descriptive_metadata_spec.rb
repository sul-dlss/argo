# frozen_string_literal: true

require 'rails_helper'

# This is an integration test (with DSA), because we need to show that the
# data we submit from here doesn't cause a round trip to MODS error.
RSpec.describe 'Descriptive metadata spreadsheet upload', :js do
  let(:item) { FactoryBot.create_for_repository(:persisted_item) }
  let(:user) { create(:user) }
  let(:object_client) { Dor::Services::Client.object(item.externalIdentifier) }

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    allow(object_client).to receive(:reindex)
    sign_in user, groups: ['sdr:administrator-role']
    visit solr_document_path(item.externalIdentifier)
  end

  after do
    file.unlink
  end

  context 'with a csv file' do
    let(:csv) do
      "title1.value,purl\nmy title,https://purl.stanford.edu/#{Druid.new(item.externalIdentifier).without_namespace}\n"
    end
    let(:file) do
      Tempfile.new(%w[upload .csv]).tap do |file|
        file.write csv
        file.close
      end
    end

    it 'uploads csv descriptive' do
      click_button 'Manage description'
      click_link 'Upload Cocina spreadsheet'

      attach_file("Upload Cocina descriptive metadata spreadsheet for #{item.externalIdentifier}", file.path)
      click_button 'Upload'

      expect(page).to have_content 'Descriptive metadata has been updated.'
      expect(object_client).to have_received(:reindex)
    end
  end

  context 'with an excel file' do
    let(:file) do
      Tempfile.new(%w[upload .xlsx]).tap do |file|
        # Open the temp file as an XLSX workbook
        workbook = WriteXLSX.new(file.path)

        # Add the initial worksheet
        worksheet = workbook.add_worksheet

        # Write our data into the sheet
        worksheet.write('A1', 'title1.value')
        worksheet.write('A2', 'my title from excel')
        worksheet.write('B1', 'purl')
        worksheet.write('B2', "https://purl.stanford.edu/#{Druid.new(item.externalIdentifier).without_namespace}")

        # Close - require to avoid file curruption
        workbook.close
      end
    end

    it 'uploads excel descriptive' do
      click_button 'Manage description'
      click_link 'Upload Cocina spreadsheet'

      attach_file("Upload Cocina descriptive metadata spreadsheet for #{item.externalIdentifier}", file.path)
      click_button 'Upload'

      expect(page).to have_content 'Descriptive metadata has been updated.'
      expect(object_client).to have_received(:reindex)
    end
  end
end
