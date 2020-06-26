# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Home page' do
  before do
    ActiveFedora::SolrService.add(id: 'druid:xb482bw3983',
                                  objectType_ssim: 'item',
                                  obj_label_tesim: 'Report about stuff',
                                  nonhydrus_collection_title_ssim: '123',
                                  current_version_isi: '1')
    ActiveFedora::SolrService.commit
    sign_in create(:user), groups: ['sdr:administrator-role']
  end

  describe 'facets' do
    it 'displays an abbreviated facet list' do
      visit root_path

      expect(page).to have_selector '.facet-field-heading', text: 'Collection'
      expect(page).not_to have_selector '.facet-field-heading', text: 'Version'
    end

    it 'has a click-through to the full facet list' do
      visit root_path

      click_link 'Show more facets'

      expect(page).to have_selector '.facet-field-heading', text: 'Collection'
      expect(page).to have_selector '.facet-field-heading', text: 'Version'
    end
  end
end
