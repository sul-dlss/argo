# encoding: utf-8

require 'spec_helper'

feature 'Search results' do
  before :each do
    @current_user = double(
      :webauth_user,
      login: 'sunetid',
      logged_in?: true,
      permitted_apos: [],
      is_admin: true
    )
    allow_any_instance_of(ApplicationController).to receive(:current_user).
      and_return(@current_user)
  end
  scenario 'contains Blacklight default index page tools' do
    visit catalog_index_path f: { empties: ['no_rights_characteristics'] }
    within '.constraints-container' do
      expect(page).to have_css '#startOverLink', text: 'Start Over'
    end
    within '#sortAndPerPage' do
      within '.page_links' do
        expect(page).to have_css '.page_entries', text: '1 - 10 of 37'
        expect(page).to have_css 'a', text: 'Next »'
      end
    end
    within '.search-widgets' do
      within '#sort-dropdown' do
        expect(page).to have_css 'button', text: 'Sort by Druid'
        expect(page).to have_css 'ul li', count: 3
      end
      within '#per_page-dropdown' do
        expect(page).to have_css 'button', text: '10 per page'
        expect(page).to have_css 'ul li', count: 4
      end
      within '.report-toggle' do
        expect(page).to have_css 'a', text: 'Bulk Update'
        expect(page).to have_css 'a', text: 'Report View'
        expect(page).to have_css 'a', text: 'Discovery Report'
        expect(page).to have_css 'a', text: 'Workflow Grid View'
      end
    end
  end
end
