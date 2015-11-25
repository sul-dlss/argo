require 'spec_helper'

RSpec.feature 'View switcher' do
  before :each do
    @current_user = double(
      :webauth_user,
      login: 'sunetid',
      logged_in?: true,
      permitted_apos: [],
      is_admin: true,
      permitted_collections: []
    )
    allow_any_instance_of(ApplicationController).to receive(:current_user).
      and_return(@current_user)
  end
  feature 'is present' do
    scenario 'bulk update' do
      visit report_bulk_url f: { objectType_ssim: ['item'] }
      within '.report-toggle' do
        expect(page).to have_css 'li.active a', text: 'Bulk Update View'
      end
    end
    scenario 'catalog results' do
      visit catalog_index_path f: { objectType_ssim: ['item'] }
      within '.report-toggle' do
        expect(page).to have_css 'ul.dropdown-menu-right li.active a', text: 'Results View'
      end
    end
    scenario 'report view' do
      visit report_url f: { objectType_ssim: ['item'] }
      within '.report-toggle' do
        expect(page).to have_css 'li.active a', text: 'Report View'
      end
    end
    scenario 'discovery report' do
      visit discovery_url f: { objectType_ssim: ['item'] }
      within '.report-toggle' do
        expect(page).to have_css 'li.active a', text: 'Discovery Report View'
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
