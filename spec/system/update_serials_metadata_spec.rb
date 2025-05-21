# frozen_string_literal: true

require 'rails_helper'

# This is an integration test (with DSA), because we need to show that the
# data we submit from here doesn't cause a round trip to MODS error.
RSpec.describe 'Update serials metadata', :js do
  let(:user) { create(:user) }
  # We need to set a catalog_record_id on this item, but we can't do it when it's created,
  # because we don't have an ILS (Folio) hooked up in our test environment. If you register
  # an object with a catalog_record_id, then DSA tries to connect to Folio to get the metadata.
  let(:item) do
    FactoryBot.create_for_repository(:persisted_item)
  end
  let(:version_service) { instance_double(VersionService, open_and_not_assembling?: true, open?: true, closeable?: true) }

  before do
    allow(VersionService).to receive(:new).and_return(version_service)
    sign_in user, groups: ['sdr:administrator-role']
    visit solr_document_path(item.externalIdentifier)
  end

  it 'edits serials' do
    click_link CatalogRecordId.manage_label

    within '.modal-body' do
      find('input').set 'a55555'
      find('select').set true
    end
    click_button 'Update'

    click_button 'Manage description'
    click_link 'Manage serials'

    fill_in 'Part label', with: 'part 17, supplement'
    fill_in 'Sort key', with: '17'
    click_button 'Update'

    expect(page).to have_content 'test object, part 17, supplement'
  end
end
