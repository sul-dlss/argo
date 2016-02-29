require 'spec_helper'

RSpec.describe 'Item registration page', js: true do
  let(:current_user) do
    mock_user(is_admin?: true)
  end
  before do
    allow_any_instance_of(ItemsController).to receive(:current_user).and_return(current_user)
  end
  it 'loads page with registration form' do
    visit register_items_path
    expect(page).to have_css '#gbox_data'
  end
end
