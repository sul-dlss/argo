# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Full width' do
  before do
    sign_in create(:user)
  end

  it 'has bootstrap full width classes' do
    visit root_path
    expect(page).to have_css '#main-container.container-fluid'
    expect(page).to have_css '#search-navbar .container-fluid'
    expect(page).to have_css '#header-navbar .container-fluid'
  end
end
