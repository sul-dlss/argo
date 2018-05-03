require 'spec_helper'

RSpec.feature 'Report view' do
  before do
    sign_in create(:user), groups: ['sdr:administrator-role']
  end

  scenario 'shows table without error' do
    visit report_path f: { objectType_ssim: ['item'] }
    expect(page).to have_css 'table#report_grid'
  end

  context 'bulk' do
    it 'should return a page with the expected elements' do
      visit '/report/bulk'
      expect(page).to have_content('Bulk update operations')
      expect(page).to have_css('.bulk_button', text: 'Get druids from search')
      expect(page).to have_css('.bulk_button', text: 'Paste a druid list')
      # expect(page).to have_css('.bulk_button', text: 'Reindex')
    end
  end
end
