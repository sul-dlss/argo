require 'spec_helper'

RSpec.describe 'catalog/_home_text.html.erb' do
  before do
    allow(view).to receive(:current_user).and_return(current_user)
  end

  context 'as someone who can view something' do
    let(:current_user) { mock_user(can_view_something?: true) }
    it 'shows the home page text' do
      render
      expect(rendered).to have_css 'p', text: 'Enter one or more search terms ' \
        'or select a facet on the left to begin.'
      expect(rendered).to have_css 'img', count: 2
    end
  end

  context 'as one who cannot view anything' do
    let(:current_user) { mock_user(can_view_something?: false) }
    it 'shows an access denied error' do
      render
      expect(rendered).to have_css 'p', text: 'You do not appear to have ' \
        'permission to view any items in Argo. Please contact an administrator.'
      expect(rendered).to have_css 'img', count: 2
    end
  end
end
