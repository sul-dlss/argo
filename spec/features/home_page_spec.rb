require 'spec_helper'

RSpec.describe 'Home page' do
  let(:current_user) do
    mock_user(is_admin?: true)
  end
  before :each do
    allow_any_instance_of(CatalogController).to receive(:current_user)
      .and_return(current_user)
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
