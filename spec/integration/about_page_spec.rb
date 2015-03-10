require 'spec_helper'

describe 'about_page' do
  before :each do
    @current_user = double(:webauth_user, :login => 'sunetid', :logged_in? => true,:privgroup=>ADMIN_GROUPS.first)
    @current_user.stub(:is_admin).and_return(true)
    @current_user.stub(:roles).and_return([])
    @current_user.stub(:is_manager).and_return(false)
    ApplicationController.any_instance.stub(:current_user).and_return(@current_user)
  end

  context 'about page tests' do
    it 'should display the about page' do
      visit '/about'
      expect(page).to have_content('Dependencies')
    end
  end
end