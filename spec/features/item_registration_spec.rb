require 'spec_helper'

RSpec.describe 'Item registration page', js: true do
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
  before do
    expect_any_instance_of(ItemsController).to receive(:current_user)
      .at_least(7).times.and_return(current_user)
  end
  it 'loads page with registration form' do
    visit register_items_path
    expect(page).to have_css '#gbox_data'
  end
end
