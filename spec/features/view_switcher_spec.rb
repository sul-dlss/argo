require 'spec_helper'

RSpec.feature 'View switcher' do
  before :each do
    admin_user # see spec_helper
  end

  feature 'is present' do
    scenario 'catalog results' do
      visit catalog_index_path f: { objectType_ssim: ['item'] }
      within '.report-toggle' do
        expect(page).to have_css 'ul.dropdown-menu-right li.active a', text: 'Results View'
      end
    end

    scenario 'report view' do
      visit report_path f: { objectType_ssim: ['item'] }
      within '.report-toggle' do
        expect(page).to have_css 'li.active a', text: 'Report View'
      end
    end

    scenario 'workflow grid' do
      visit report_workflow_grid_url f: { objectType_ssim: ['item'] }
      within '.report-toggle' do
        expect(page).to have_css 'li.active a', text: 'Workflow Grid View'
      end
    end
  end
end
