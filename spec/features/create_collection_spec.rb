# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Add collection' do
  before do
    allow(Dor::Collection).to receive(:where).and_return([1])
    sign_in create(:user), groups: ['sdr:administrator-role']
  end

  describe 'when collection catkey is provided', js: true do
    it 'warns if catkey exists' do
      visit new_apo_collection_path 'druid:zt570tx3016'
      choose 'Create a Collection from Symphony'
      expect(page).to have_text('Collection Catkey')
      expect(page).not_to have_text('already exists')
      fill_in 'collection_catkey', with: 'foo'
      expect(page).to have_text('already exists')
    end
  end

  describe 'when collection title is provided', js: true do
    it 'warns if title exists' do
      visit new_apo_collection_path 'druid:zt570tx3016'
      expect(page).to have_text('Collection Title')
      expect(page).not_to have_text('already exists')
      fill_in 'collection_title', with: 'foo'
      expect(page).to have_text('already exists')
    end
  end
end
