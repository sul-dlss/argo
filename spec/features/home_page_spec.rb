# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Home page' do
  let(:blacklight_config) { CatalogController.blacklight_config }
  let(:solr_conn) { blacklight_config.repository_class.new(blacklight_config).connection }

  before do
    solr_conn.add(id: 'druid:xb482bw3983',
                  objectType_ssim: 'item',
                  main_title_tenim: 'Report about stuff',
                  collection_title_ssim: '123',
                  current_version_isi: '1')
    solr_conn.commit
    sign_in create(:user), groups: ['sdr:administrator-role']
  end

  describe 'facets' do
    it 'displays an abbreviated facet list' do
      visit root_path

      expect(page).to have_css '.facet-field-heading', text: 'Collection'
      expect(page).to have_no_css '.facet-field-heading', text: 'Version'
    end

    it 'has a click-through to the full facet list' do
      visit root_path

      click_link 'Show more facets'

      expect(page).to have_css '.facet-field-heading', text: 'Collection'
      expect(page).to have_css '.facet-field-heading', text: 'Version'
    end
  end
end
