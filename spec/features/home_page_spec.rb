# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Home page' do
  before do
    sign_in create(:user), groups: ['sdr:administrator-role']
  end

  describe 'facets' do
    it 'displays an abbreviated facet list' do
      visit root_path

      expect(page).to have_selector '.facet-field-heading', text: 'Collection'
      expect(page).not_to have_selector '.facet-field-heading', text: 'Version'
    end

    it 'has a click-through to the full facet list' do
      visit root_path

      click_link 'Show more facets'

      expect(page).to have_selector '.facet-field-heading', text: 'Collection'
      expect(page).to have_selector '.facet-field-heading', text: 'Version'
    end
  end
end
