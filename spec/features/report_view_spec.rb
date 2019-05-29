# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Report view' do
  before do
    sign_in create(:user), groups: ['sdr:administrator-role']
  end

  it 'shows table without error' do
    visit report_path f: { objectType_ssim: ['item'] }
    expect(page).to have_css 'table#report_grid'
  end

  context 'bulk' do
    it 'returns a page with the expected elements' do
      visit '/report/bulk'
      expect(page).to have_content('Bulk update operations')
      expect(page).to have_css('.bulk_button', text: 'Get druids from search')
      expect(page).to have_css('.bulk_button', text: 'Paste a druid list')
      # expect(page).to have_css('.bulk_button', text: 'Reindex')
    end
  end
end
