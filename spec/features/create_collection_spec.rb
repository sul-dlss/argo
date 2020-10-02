# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Add collection' do
  before do
    allow(Dor::Collection).to receive(:where).and_return([1])
    allow(Dor).to receive(:find).with(apo_id).and_return(apo)
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    sign_in create(:user), groups: ['sdr:administrator-role']
  end

  let(:apo_id) { 'druid:vt333hq2222' }
  let(:apo) { instance_double(Dor::AdminPolicyObject, label: 'hey', pid: apo_id) }
  let(:cocina_model) { instance_double(Cocina::Models::AdminPolicy) }
  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model) }

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
