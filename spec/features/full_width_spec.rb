require 'spec_helper'

feature 'Full width' do
  before :each do
    admin_user # see spec_helper
  end

  scenario 'has bootstrap full width classes' do
    visit root_path
    expect(page).to have_css '#main-container.container-fluid'
    expect(page).to have_css '#search-navbar .container-fluid'
    expect(page).to have_css '#header-navbar .container-fluid'
  end
end
