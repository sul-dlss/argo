# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Date range form', js: true do
  let(:tomorrow) { (1.day.from_now).strftime('%m/%d/%Y') }
  let(:last_modified) { Time.new.utc.beginning_of_day.iso8601 }
  let(:blacklight_config) { CatalogController.blacklight_config }
  let(:solr_conn) { blacklight_config.repository_class.new(blacklight_config).connection }

  before do
    solr_conn.delete_by_query("#{SolrDocument::FIELD_OBJECT_TYPE}:item")
    solr_conn.add(id: 'druid:xb482ww9999',
                  objectType_ssim: 'item',
                  obj_label_tesim: 'Report about stuff',
                  SolrDocument::FIELD_LAST_MODIFIED_DATE => last_modified)
    solr_conn.add(id: 'druid:xb482bw3980',
                  objectType_ssim: 'item',
                  obj_label_tesim: 'Report about stuff',
                  SolrDocument::FIELD_LAST_MODIFIED_DATE => last_modified)
    solr_conn.add(id: 'druid:xb482bw3981',
                  objectType_ssim: 'item',
                  obj_label_tesim: 'Report about stuff',
                  SolrDocument::FIELD_LAST_MODIFIED_DATE => last_modified)
    solr_conn.add(id: 'druid:xb482bw3982',
                  objectType_ssim: 'item',
                  obj_label_tesim: 'Report about stuff',
                  SolrDocument::FIELD_LAST_MODIFIED_DATE => last_modified)
    solr_conn.add(id: 'druid:xb482bw3983',
                  objectType_ssim: 'item',
                  obj_label_tesim: 'Report about stuff',
                  SolrDocument::FIELD_LAST_MODIFIED_DATE => last_modified)
    solr_conn.commit
    sign_in create(:user), groups: ['sdr:administrator-role']
  end

  context 'with empty queries' do
    let(:query_params) { {} }

    before do
      visit root_path(query_params.merge(all: true))
      click_button 'Last Modified'
    end

    it 'navigates to date range search' do
      within '#facet-object_modified_date' do
        fill_in 'object_modified_date_after_datepicker', with: '01/01/1990'
        fill_in 'object_modified_date_before_datepicker', with: tomorrow
        find('input[type="submit"]').click
      end
      using_wait_time 45 do
        find('#appliedParams')
        within '.constraints-container' do
          expect(page).to have_css '.filter-name', text: 'Last Modified'
          expect(page).to have_css(
            '.filter-value', text: /^\[1990-01-01T\d{2}:00:00.000Z TO 20.*59:59.000Z\]/
          )
        end
      end
      within '.page-links' do
        expect(page).to have_css '.page-entries', text: /1 - \d+ of \d+/
      end
    end

    it 'with no after date' do
      within '#facet-object_modified_date' do
        fill_in 'object_modified_date_before_datepicker', with: tomorrow
        find('input[type="submit"]').click
      end
      using_wait_time 45 do
        find('#appliedParams')
        within '.constraints-container' do
          expect(page).to have_css '.filter-name', text: 'Last Modified'
          expect(page).to have_css(
            '.filter-value', text: /^\[\* TO 20.*59:59.000Z\]/
          )
        end
      end
    end

    it 'with no before date' do
      within '#facet-object_modified_date' do
        fill_in 'object_modified_date_after_datepicker', with: '01/01/1990'
        find('input[type="submit"]').click
      end
      using_wait_time 45 do
        find('#appliedParams')
        within '.constraints-container' do
          expect(page).to have_css '.filter-name', text: 'Last Modified'
          expect(page).to have_css(
            '.filter-value', text: /^\[1990-01-01T\d{2}:00:00.000Z TO \*\]/
          )
        end
      end
    end
  end

  context 'with selected facets and search queries' do
    let(:query_params) { { q: 'Reports', f: { objectType_ssim: ['item'] } } }

    before do
      visit root_path(query_params.merge(all: true))
      find('[data-target="#facet-object_modified_date"]').click
    end

    it 'includes existing parameters in the new query' do
      within '#facet-object_modified_date' do
        fill_in 'object_modified_date_after_datepicker', with: '01/01/1990'
        find('input[type="submit"]').click
      end

      find('#appliedParams')
      expect(page).to have_content '1 - 5 of 5'
      within '.constraints-container' do
        expect(page).to have_css '.filter-value', text: 'Reports'
        expect(page).to have_css '.filter-name', text: 'Last Modified'
        expect(page).to have_css '.filter-name', text: 'Object Type'
      end
    end
  end
end
