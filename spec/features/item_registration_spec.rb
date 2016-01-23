require 'spec_helper'

RSpec.describe 'Item registration page', js: true do
  before :each do
    admin_user # see spec_helper
  end

  it 'loads page with registration form' do
    visit register_items_path
    expect(page).to have_css '#gbox_data'
  end
end
