# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Date range form', js: true do
  let(:query_params) { {} }
  let(:tomorrow) { (Time.current + 1.day).strftime('%m/%d/%Y') }

  before do
    sign_in create(:user), groups: ['sdr:administrator-role']
    visit root_path(query_params.merge(all: true))
    find('[data-target="#facet-object_modified_date"]').click
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

  describe 'with selected facets and search queries' do
    let(:query_params) { { q: 'Reports', f: { objectType_ssim: ['item'] } } }

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
