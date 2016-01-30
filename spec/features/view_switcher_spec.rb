require 'spec_helper'

RSpec.feature 'View switcher' do
  let(:current_user) do
    double(
      :webauth_user,
      login: 'sunetid',
      logged_in?: true,
      permitted_apos: [],
      is_admin: true,
      roles: [],
      groups: [],
      permitted_collections: []
    )
  end

  feature 'is present' do
    scenario 'catalog results' do
      expect_any_instance_of(CatalogController).to receive(:current_user)
        .at_least(1).times.and_return(current_user)
      visit catalog_index_path f: { objectType_ssim: ['item'] }
      within '.report-toggle' do
        expect(page).to have_css 'ul.dropdown-menu-right li.active a', text: 'Results View'
      end
    end
    scenario 'report view' do
      expect_any_instance_of(ReportController).to receive(:current_user)
        .at_least(1).times.and_return(current_user)
      visit report_path f: { objectType_ssim: ['item'] }
      within '.report-toggle' do
        expect(page).to have_css 'li.active a', text: 'Report View'
      end
    end
    scenario 'discovery report' do
      expect_any_instance_of(DiscoveryController).to receive(:current_user)
        .at_least(1).times.and_return(current_user)
      visit discovery_url f: { objectType_ssim: ['item'] }
      within '.report-toggle' do
        expect(page).to have_css 'li.active a', text: 'Discovery Report View'
      end
    end
    scenario 'workflow grid' do
      expect_any_instance_of(ReportController).to receive(:current_user)
        .at_least(1).times.and_return(current_user)
      visit report_workflow_grid_url f: { objectType_ssim: ['item'] }
      within '.report-toggle' do
        expect(page).to have_css 'li.active a', text: 'Workflow Grid View'
      end
    end
  end
end
