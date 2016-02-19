require 'spec_helper'

feature 'Report view' do
  let(:current_user) do
    double(
      :webauth_user,
      login: 'sunetid',
      logged_in?: true,
      permitted_apos: [],
      is_admin: true,
      roles: [],
      groups: []
    )
  end
  before :each do
    allow_any_instance_of(ReportController).to receive(:current_user).
      and_return(current_user)
  end
  scenario 'shows table without error' do
    visit report_path f: { objectType_ssim: ['item'] }
    expect(page).to have_css 'table#report_grid'
  end
end
