require 'spec_helper'

feature 'Report view' do
  before :each do
    admin_user # see spec_helper
  end

  scenario 'shows table without error' do
    visit report_path f: { objectType_ssim: ['item'] }
    expect(page).to have_css 'table#report_grid'
  end
end
