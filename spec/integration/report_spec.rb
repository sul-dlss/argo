require 'spec_helper'

describe ReportController, :type => :feature do
  before :each do
    webauth = double('WebAuth', :login => 'sunetid', :attributes => {'DISPLAYNAME' => 'Example User'}, :privgroup => ADMIN_GROUPS.first)
    @current_user = User.find_or_create_by_webauth(webauth)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(@current_user)
  end
  describe 'bulk' do
    it 'should return a page with the expected elements' do
      visit '/report/bulk'
      expect(page).to have_content('Bulk update operations')
      expect(page).to have_css('.bulk_button', text: 'Get druids from search')
      expect(page).to have_css('.bulk_button', text: 'Paste a druid list')
      # expect(page).to have_css('.bulk_button', text: 'Reindex')
    end
  end
end
