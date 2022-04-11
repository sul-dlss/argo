# frozen_string_literal: true

require 'rails_helper'

# This is an integration test (with DSA), because we need to show that the
# data we submit from here doesn't cause a round trip to MODS error.
RSpec.describe 'Update serials metadata', js: true do
  let(:user) { create(:user) }
  # We need to set a catkey on this item, but we can't do it when it's created,
  # because we don't have symphony running in our test environment. If you register
  # an object with a catkey, then DSA tries to connect to symphony to get the metadata.
  let(:item) do
    FactoryBot.create_for_repository(:persisted_item)
  end

  before do
    sign_in user, groups: ['sdr:administrator-role']
    visit solr_document_path(item.externalIdentifier)
  end

  it 'edits serials' do
    click_link 'Manage catkey'
    fill_in 'Catkey', with: '55555'
    click_button 'Update'

    click_button 'Manage description'
    click_link 'Manage serials'

    fill_in 'Part number', with: 'part 17'
    fill_in 'Part name', with: 'supplement'
    fill_in 'Sort field', with: '17'
    click_button 'Update'

    expect(page).to have_content 'test object. part 17, supplement'
  end
end
