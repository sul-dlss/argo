# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Add collection' do
  before do
    allow(Blacklight::Solr::Repository).to receive(:new).and_return(repo)
    allow(Repository).to receive(:find).and_return(build(:admin_policy))
    sign_in create(:user), groups: ['sdr:administrator-role']
  end

  let(:repo) { instance_double(Blacklight::Solr::Repository, connection: solr_client) }
  let(:solr_client) { instance_double(RSolr::Client, get: result) }
  let(:result) { { 'response' => { 'numFound' => 1 } } }
  let(:apo_id) { 'druid:vt333hq2222' }

  describe 'when collection catkey is provided', js: true do
    it 'warns if catkey exists' do
      visit new_apo_collection_path apo_id
      choose 'Create a Collection from Symphony'
      expect(page).to have_text('Collection Catkey')
      expect(page).not_to have_text('already exists')
      fill_in 'collection_catkey', with: 'foo'
      expect(page).to have_text('already exists')
    end
  end

  describe 'when collection title is provided', js: true do
    it 'warns if title exists' do
      visit new_apo_collection_path apo_id
      expect(page).to have_text('Collection Title')
      expect(page).not_to have_text('already exists')
      fill_in 'collection_title', with: 'foo'
      expect(page).to have_text('already exists')
    end
  end
end
