# coding: utf-8
require 'spec_helper'

feature 'Search results' do
  let(:current_user) do
    double(
      :webauth_user,
      login: 'sunetid',
      logged_in?: true,
      permitted_apos: [],
      is_admin: true,
      roles: [],
      groups: []
    )
  end
  before :each do
    allow_any_instance_of(CatalogController).to receive(:current_user).
      and_return(current_user)
  end
  scenario 'contains Blacklight default index page tools' do
    visit catalog_index_path f: { empties: ['no_rights_characteristics'] }
    within '.constraints-container' do
      expect(page).to have_css '#startOverLink', text: 'Start Over'
    end
    within '#sortAndPerPage' do
      within '.page_links' do
        expect(page).to have_css '.page_entries', text: '1 - 10 of 38'
        expect(page).to have_css 'a', text: 'Next »'
      end
    end
    within '.search-widgets' do
      within '#bulk-update-button' do
        expect(page).to have_css 'a.btn.btn-default', text: 'Bulk Update'
      end
      expect(page).to have_css 'a.btn.btn-default', text: 'Bulk Action'
      within '#sort-dropdown' do
        expect(page).to have_css 'button', text: 'Sort by Druid'
        expect(page).to have_css 'ul li', count: 3
      end
      within '#per_page-dropdown' do
        expect(page).to have_css 'button', text: '10 per page'
        expect(page).to have_css 'ul li', count: 4
      end
      within '.report-toggle' do
        expect(page).to have_css 'a', text: 'Report View'
        expect(page).to have_css 'a', text: 'Workflow Grid View'
      end
    end
  end
  scenario 'contains appropriate metadata fields' do
    visit catalog_index_path f: { objectType_ssim: ['item'] }
    within('.document', match: :first) do
      within '.document-metadata' do
        expect(page).to have_css 'dt', text: 'DRUID:'
        expect(page).to have_css 'dd', text: 'druid:hj185vb7593'
        expect(page).to have_css 'dt', text: 'Object Type:'
        expect(page).to have_css 'dd', text: 'item'
        expect(page).to have_css 'dt', text: 'Content Type:'
        expect(page).to have_css 'dd', text: 'image'
        expect(page).to have_css 'dt', text: 'Status:'
        expect(page).to have_css 'dd', text: 'v1 Unknown Status'
        expect(page).to have_css 'dt', text: 'Admin Policy:'
        expect(page).to have_css 'dd a', text: 'Stanford University Libraries - Special Collections'
        expect(page).to have_css 'dt', text: 'Project:'
        expect(page).to have_css 'dd a', text: 'Fuller Slides'
        expect(page).to have_css 'dt', text: 'IDs'
        expect(page).to have_css 'dd', text: 'fuller:M1090_S15_B02_F01_0126, uuid:ad2d8894-7eba-11e1-b714-0016034322e7'
        expect(page).to have_css 'dt', text: 'Label:'
        expect(page).to have_css 'dd', text: 'M1090_S15_B02_F01_0126'
        expect(page).to have_css 'dt', text: 'Source:'
        expect(page).to have_css 'dd', text: 'fuller:M1090_S15_B02_F01_0126'
        expect(page).to have_css 'dt', text: 'Preservation Size:'
        expect(page).to have_css 'dd', text: '53.2 MB'
      end
    end
    expect(page).to have_css 'dt', text: 'Collection:'
    expect(page).to have_css 'dd a', text: /Annual report/
  end
  scenario 'contains document image thumbnail' do
    visit catalog_index_path f: { objectType_ssim: ['item'] }
    expect(page).to have_css '.document-thumbnail a img'
  end
end
