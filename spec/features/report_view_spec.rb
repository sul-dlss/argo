require 'spec_helper'

feature 'Report view' do
  before :each do
    @current_user = double(
      :webauth_user,
      login: 'sunetid',
      logged_in?: true,
      permitted_apos: [],
      is_admin: true
    )
    allow_any_instance_of(ApplicationController).to receive(:current_user).
      and_return(@current_user)
  end
  scenario 'shows table without error' do
    visit report_path f: { objectType_ssim: ['item'] }
    expect(page).to have_css 'table#report_grid'
  end
end
