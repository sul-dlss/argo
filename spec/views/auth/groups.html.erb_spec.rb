require 'spec_helper'

RSpec.describe 'auth/groups.html.erb' do
  before do
    expect(view).to receive(:current_user).at_least(:once).and_return(user)
  end
  context 'as admin' do
    let(:user) { double('admin', is_admin: true, groups: ['dlss', 'dpg']) }
    it 'shows groups and impersonate form' do
      render
      expect(rendered).to have_css 'h3', text: 'Your Current Groups'
      expect(rendered).to have_css 'li', text: 'dlss'
      expect(rendered).to have_css 'li', text: 'dpg'
      expect(rendered).to have_css 'label', text: 'Enter a group or a comma separated list of groups to impersonate'
      expect(rendered).to have_css 'input#groups[type="text"]'
      expect(rendered).to have_css 'input[type="submit"][value="Impersonate"]'
    end
  end
  context 'not admin' do
    let(:user) { double('user', is_admin: false) }
    it 'does not show groups or form' do
      render
      expect(rendered).to_not have_css 'h3', text: 'Your Current Groups'
      expect(rendered).to_not have_css 'form'
    end
  end
end
