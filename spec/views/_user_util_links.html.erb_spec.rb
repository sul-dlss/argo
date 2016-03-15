require 'spec_helper'

describe '_user_util_links.html.erb' do
  before do
    allow(view).to receive(:current_user).and_return(current_user)
    allow(controller).to receive(:current_user).and_return(current_user)
  end

  context 'with regular user' do
    let(:current_user) { mock_user }
    it 'renders navigation links' do
      render
      expect(rendered).to have_css '.navbar-right'
      expect(rendered).to have_css 'ul.nav.navbar-nav'
      expect(rendered).to have_css 'li', count: 6
      expect(rendered).to have_css 'li.dropdown ul li a', text: 'Register Items'
      expect(rendered).to_not have_css 'li.dropdown ul li a', text: 'Register APO'
    end
  end
  context 'with admin user' do
    let(:current_user) { mock_user(is_admin?: true) }
    it 'renders navigation links' do
      render
      expect(rendered).to have_css '.navbar-right'
      expect(rendered).to have_css 'ul.nav.navbar-nav'
      expect(rendered).to have_css 'li', count: 8
      expect(rendered).to have_css 'li.dropdown ul li a', text: 'Register Items'
      expect(rendered).to have_css 'li.dropdown ul li a', text: 'Register APO'
      expect(rendered).to have_css 'li', text: 'Impersonate'
    end
  end
  context 'while impersonating' do
    let(:current_user) { mock_user(is_admin?: true) }
    let(:session) { { groups: ['cool', 'stuff'] } }
    it 'renders impersonation content' do
      expect(view).to receive(:session).and_return(session).exactly(2).times
      render
      expect(rendered).to have_css 'a', text: 'Impersonating: cool stuff'
      expect(rendered).to have_css 'a', text: 'Stop Impersonating'
    end
  end
  context 'with manager user' do
    let(:current_user) { mock_user(is_manager?: true) }
    it 'renders navigation links' do
      render
      expect(rendered).to have_css '.navbar-right'
      expect(rendered).to have_css 'ul.nav.navbar-nav'
      expect(rendered).to have_css 'li', count: 7
    end
  end
end
