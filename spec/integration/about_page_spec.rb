require 'spec_helper'

describe 'about_page', :type => :request do
  before :each do
    admin_user # see spec_helper
  end

  context 'about page tests' do
    it 'should display the about page' do
      visit '/about'
      expect(page).to have_content('Dependencies')
    end
  end
end
