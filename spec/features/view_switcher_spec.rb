# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'View switcher' do
  before do
    sign_in create(:user), groups: ['sdr:administrator-role']
  end

  describe 'is present' do
    it 'catalog results' do
      visit search_catalog_path f: { objectType_ssim: ['item'] }
      within '.report-toggle' do
        expect(page).to have_css 'ul.dropdown-menu-right li.active a', text: 'Results View'
      end
    end

    it 'report view' do
      visit report_path f: { objectType_ssim: ['item'] }
      within '.report-toggle' do
        expect(page).to have_css 'li.active a', text: 'Report View'
      end
    end

    it 'workflow grid' do
      visit report_workflow_grid_url f: { objectType_ssim: ['item'] }
      within '.report-toggle' do
        expect(page).to have_css 'li.active a', text: 'Workflow Grid View'
      end
    end
  end
end
