# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Date range form', :js do
  let(:tomorrow) { 1.day.from_now.strftime('%m/%d/%Y') }
  let(:last_published) { Time.new.utc.beginning_of_day.iso8601 }
  let(:blacklight_config) { CatalogController.blacklight_config }
  let(:solr_conn) { blacklight_config.repository_class.new(blacklight_config).connection }

  before do
    solr_conn.delete_by_query("#{SolrDocument::FIELD_OBJECT_TYPE}:item")
    solr_conn.add(:id => 'druid:xb482ww9999',
                  SolrDocument::FIELD_OBJECT_TYPE => 'item',
                  :obj_label_tesim => 'Report about stuff',
                  SolrDocument::FIELD_LAST_PUBLISHED_DATE => last_published)
    solr_conn.add(:id => 'druid:xb482bw3980',
                  SolrDocument::FIELD_OBJECT_TYPE => 'item',
                  :obj_label_tesim => 'Report about stuff',
                  SolrDocument::FIELD_LAST_PUBLISHED_DATE => last_published)
    solr_conn.add(:id => 'druid:xb482bw3981',
                  SolrDocument::FIELD_OBJECT_TYPE => 'item',
                  :obj_label_tesim => 'Report about stuff',
                  SolrDocument::FIELD_LAST_PUBLISHED_DATE => last_published)
    solr_conn.add(:id => 'druid:xb482bw3982',
                  SolrDocument::FIELD_OBJECT_TYPE => 'item',
                  :obj_label_tesim => 'Report about stuff',
                  SolrDocument::FIELD_LAST_PUBLISHED_DATE => last_published)
    solr_conn.add(:id => 'druid:xb482bw3983',
                  SolrDocument::FIELD_OBJECT_TYPE => 'item',
                  :obj_label_tesim => 'Report about stuff',
                  SolrDocument::FIELD_LAST_PUBLISHED_DATE => last_published)
    solr_conn.commit
    sign_in create(:user), groups: ['sdr:administrator-role']
  end

  context 'with empty queries' do
    let(:query_params) { {} }

    before do
      visit root_path(query_params.merge(all: true))
      scroll_to find_by_id('facet-published_latest_date-header')
      click_button 'Last Published'
    end

    it 'navigates to date range search' do
      within '#facet-published_latest_date' do
        fill_in 'published_latest_date_after_datepicker', with: '01/01/1990'
        fill_in 'published_latest_date_before_datepicker', with: tomorrow
        find('input[type="submit"]').click
      end
      using_wait_time 45 do
        find_by_id('appliedParams')
        within '.constraints-container' do
          expect(page).to have_css '.filter-name', text: 'Last Published'
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
      within '#facet-published_latest_date' do
        fill_in 'published_latest_date_before_datepicker', with: tomorrow
        find('input[type="submit"]').click
      end
      using_wait_time 45 do
        find_by_id('appliedParams')
        within '.constraints-container' do
          expect(page).to have_css '.filter-name', text: 'Last Published'
          expect(page).to have_css(
            '.filter-value', text: /^\[\* TO 20.*59:59.000Z\]/
          )
        end
      end
    end

    it 'with no before date' do
      within '#facet-published_latest_date' do
        fill_in 'published_latest_date_after_datepicker', with: '01/01/1990'
        find('input[type="submit"]').click
      end
      using_wait_time 45 do
        find_by_id('appliedParams')
        within '.constraints-container' do
          expect(page).to have_css '.filter-name', text: 'Last Published'
          expect(page).to have_css(
            '.filter-value', text: /^\[1990-01-01T\d{2}:00:00.000Z TO \*\]/
          )
        end
      end
    end
  end

  context 'with selected facets and search queries' do
    let(:query_params) { { q: 'Reports', f: { SolrDocument::FIELD_OBJECT_TYPE => ['item'] } } }

    before do
      visit root_path(query_params.merge(all: true))
      scroll_to find_by_id('facet-published_latest_date-header')
      find('[data-target="#facet-published_latest_date"]').click
    end

    it 'includes existing parameters in the new query' do
      within '#facet-published_latest_date' do
        fill_in 'published_latest_date_after_datepicker', with: '01/01/1990'
        find('input[type="submit"]').click
      end

      find_by_id('appliedParams')
      expect(page).to have_content '1 - 5 of 5'
      within '.constraints-container' do
        expect(page).to have_css '.filter-value', text: 'Reports'
        expect(page).to have_css '.filter-name', text: 'Last Published'
        expect(page).to have_css '.filter-name', text: 'Object Type'
      end
    end
  end
end
