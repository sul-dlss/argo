require 'spec_helper'

describe ReportController, :type => :feature do
  before :each do
    webauth = double('WebAuth', :login => 'sunetid', :attributes => {'DISPLAYNAME' => 'Example User'}, :privgroup => ADMIN_GROUPS.first)
    @current_user = User.find_or_create_by_webauth(webauth)
    ##
    # A higher level up the inheritance chain stub of `ApplicationController` is
    # insufficient here, due to a possible bug in rspec-mocks or our overuse of
    # `allow_any_instance_of`.
    allow_any_instance_of(CatalogController).to receive(:current_user).and_return(@current_user)
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
