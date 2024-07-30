# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Full width' do
  before do
    sign_in create(:user)
  end

  it 'has bootstrap full width classes' do
    visit root_path
    expect(page).to have_css '#main-container.container-fluid'

    # but not in the top bar
    expect(page).to have_css 'nav.navbar .container'
    expect(page).to have_css '.masthead .container'
    expect(page).to have_css '.navbar-search .container'
  end
end
