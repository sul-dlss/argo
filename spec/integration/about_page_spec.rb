require 'spec_helper'

describe 'about_page', :type => :request do
  before :each do
    @current_user = double(:webauth_user, :login => 'sunetid', :logged_in? => true,:privgroup=>ADMIN_GROUPS.first)
    allow(@current_user).to receive(:is_admin).and_return(true)
    allow(@current_user).to receive(:roles).and_return([])
    allow(@current_user).to receive(:is_manager).and_return(false)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(@current_user)
  end

  context 'about page tests' do
    it 'should display the about page' do
      visit '/about'
      expect(page).to have_content('Dependencies')
    end
  end
end