# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Report view' do
  before do
    sign_in create(:user), groups: ['sdr:administrator-role']
  end

  describe 'the show page', :js do
    let(:blacklight_config) { CatalogController.blacklight_config }
    let(:solr_conn) { blacklight_config.repository_class.new(blacklight_config).connection }

    before do
      solr_conn.add(id: 'druid:hj185xx2222',
                    SolrDocument::FIELD_OBJECT_TYPE => 'item',
                    display_title_ss: 'Slides, IA 11, Geodesic Domes, Double Skin "Growth" House, N.C. State, 1953')
      solr_conn.commit
    end

    it 'shows table without error' do
      visit report_path f: { SolrDocument::FIELD_OBJECT_TYPE => ['item'] }
      expect(page).to have_css 'div#objectsTable'
      expect(page).to have_content('hj185xx2222')
    end

    it 'shows the column selector when clicked' do
      visit report_path f: { SolrDocument::FIELD_OBJECT_TYPE => ['item'] }
      click_button('Columns')
      expect(page).to have_content('Select Columns to Display and Download')
      # count the # of total fields
      expect(page).to have_css('input.form-check-input',
                               count: Report::REPORT_FIELDS.count)
      # count the # of fields displayed by default
      expect(page).to have_css('input.form-check-input:checked',
                               count: Report::REPORT_FIELDS.count { |field| field[:default] })
    end
  end
end
