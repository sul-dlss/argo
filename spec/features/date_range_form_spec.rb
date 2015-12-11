require 'spec_helper'

RSpec.feature 'Date range form', js: true do
  before do
    @current_user = double(
      :webauth_user,
      login: 'sunetid',
      logged_in?: true,
      permitted_apos: [],
      is_admin: true,
      roles: []
    )
    allow_any_instance_of(ApplicationController).to receive(:current_user).
      and_return(@current_user)
    visit root_path
    find('[data-target="#facet-object_modified_date"]').click
  end
  def wait_for_applied_params
    counter = 1
    loop do
      break if first('#appliedParams')
      sleep 2 * Math.log(counter += 1)
      expect(true).to be false if counter > 45
    end
  end
  let(:tomorrow) { (Time.current + 1.day).strftime('%m/%d/%Y') }
  scenario 'navigates to date range search' do
    within '#facet-object_modified_date' do
      fill_in 'object_modified_date_after_datepicker', with: '01/01/1990'
      fill_in 'object_modified_date_before_datepicker', with: tomorrow
      find('input[type="submit"]').trigger(:click)
    end
    wait_for_applied_params
    within '.constraints-container' do
      expect(page).to have_css '.filterName', text: 'Last Modified'
      expect(page).to have_css(
        '.filterValue', text: /^\[1990-01-01T\d{2}:00:00.000Z TO 20.*59:59.000Z\]/
      )
    end
    within '.page_links' do
      expect(page).to have_css '.page_entries', text: /1 - \d+ of \d+/
    end
  end
  scenario 'with no after date' do
    within '#facet-object_modified_date' do
      fill_in 'object_modified_date_before_datepicker', with: tomorrow
      find('input[type="submit"]').trigger(:click)
    end
    wait_for_applied_params
    within '.constraints-container' do
      expect(page).to have_css '.filterName', text: 'Last Modified'
      expect(page).to have_css(
        '.filterValue', text: /^\[\* TO 20.*59:59.000Z\]/
      )
    end
  end
  scenario 'with no before date' do
    within '#facet-object_modified_date' do
      fill_in 'object_modified_date_after_datepicker', with: '01/01/1990'
      find('input[type="submit"]').trigger(:click)
    end
    wait_for_applied_params
    within '.constraints-container' do
      expect(page).to have_css '.filterName', text: 'Last Modified'
      expect(page).to have_css(
        '.filterValue', text: /^\[1990-01-01T\d{2}:00:00.000Z TO \*\]/
      )
    end
  end
end
