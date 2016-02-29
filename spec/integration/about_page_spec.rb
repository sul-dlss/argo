require 'spec_helper'

describe 'about_page', :type => :request do
  before :each do
    @current_user = mock_user(is_admin?: true)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(@current_user)
  end

  context 'about page tests' do
    it 'should display the about page' do
      visit '/about'
      expect(page).to have_content('Dependencies')
    end
  end
end
