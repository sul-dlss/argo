require 'spec_helper'

describe '_user_util_links.html.erb' do
  context 'with regular user' do
    let(:current_user) { double('current_user', is_admin: false, is_manager: false) }
    it 'renders navigation links' do
      expect(view).to receive(:current_user).and_return(current_user).exactly(5).times
      render
      expect(rendered).to have_css '.navbar-right'
      expect(rendered).to have_css 'ul.nav.navbar-nav'
      expect(rendered).to have_css 'li', count: 6
    end
  end
  context 'with admin user' do
    let(:current_user) { double('current_user', is_admin: true, is_manager: false) }
    it 'renders navigation links' do
      expect(view).to receive(:current_user).and_return(current_user).exactly(4).times
      render
      expect(rendered).to have_css '.navbar-right'
      expect(rendered).to have_css 'ul.nav.navbar-nav'
      expect(rendered).to have_css 'li', count: 8
    end
  end
  context 'with manager user' do
    let(:current_user) { double('current_user', is_admin: false, is_manager: true) }
    it 'renders navigation links' do
      expect(view).to receive(:current_user).and_return(current_user).exactly(5).times
      render
      expect(rendered).to have_css '.navbar-right'
      expect(rendered).to have_css 'ul.nav.navbar-nav'
      expect(rendered).to have_css 'li', count: 7
    end
  end
end
