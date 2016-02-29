require 'spec_helper'

feature 'Full width' do
  before :each do
    @current_user = mock_user(is_admin?: true, can_view_something?: true)
    allow_any_instance_of(ApplicationController).to receive(:current_user).
      and_return(@current_user)
  end
  scenario 'has bootstrap full width classes' do
    visit root_path
    expect(page).to have_css '#main-container.container-fluid'
    expect(page).to have_css '#search-navbar .container-fluid'
    expect(page).to have_css '#header-navbar .container-fluid'
  end
end
