require 'spec_helper'

RSpec.describe 'catalog/_home_text.html.erb' do
  it 'as someone who can view something' do
    expect(view).to receive_message_chain(:current_user, :can_view_something?) { true }
    render
    expect(rendered).to have_css 'p', text: 'Enter one or more search terms ' \
      'or select a facet on the left to begin.'
    expect(rendered).to have_css 'img', count: 2
  end
  it 'as one who cannot view anything' do
    expect(view).to receive_message_chain(:current_user, :can_view_something?) { false }
    render
    expect(rendered).to have_css 'p', text: 'You do not appear to have ' \
      'permission to view any items in Argo. Please contact an administrator.'
    expect(rendered).to have_css 'img', count: 2
  end
end
