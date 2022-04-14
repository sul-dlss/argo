# frozen_string_literal: true

require 'rails_helper'

# This is an integration test (with DSA), because we need to show that the
# data we submit from here doesn't cause a round trip to MODS error.
RSpec.describe 'Descriptive metadata spreadsheet upload', js: true do
  let(:user) { create(:user) }
  # We need to set a catkey on this item, but we can't do it when it's created,
  # because we don't have symphony running in our test environment. If you register
  # an object with a catkey, then DSA tries to connect to symphony to get the metadata.
  let(:item) do
    FactoryBot.create_for_repository(:persisted_item)
  end

  let(:csv) do
    "title1:value,purl\nmy title,https://purl.stanford.edu/#{Druid.new(item.externalIdentifier).without_namespace}\n"
  end
  let(:file) do
    Tempfile.new('upload.csv').tap do |file|
      file.write csv
      file.close
    end
  end

  after do
    file.unlink
  end

  before do
    sign_in user, groups: ['sdr:administrator-role']
    visit solr_document_path(item.externalIdentifier)
  end

  it 'uploads descriptive' do
    click_button 'Manage description'
    click_link 'Upload Cocina spreadsheet'

    attach_file("Upload Cocina descriptive metadata spreadsheet for #{item.externalIdentifier}", file.path)
    click_button 'Upload'

    expect(page).to have_content 'Descriptive metadata has been updated.'
  end
end
