# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'catalog/_home_text.html.erb' do
  before do
    @presenter = presenter
    render
  end

  context 'as someone who can view something' do
    let(:presenter) { instance_double(HomeTextPresenter, view_something?: true) }

    it 'shows the home page text' do
      expect(rendered).to have_css 'p', text: 'Enter one or more search terms ' \
        'or select a facet on the left to begin.'
    end
  end

  context 'as one who cannot view anything' do
    let(:presenter) { instance_double(HomeTextPresenter, view_something?: false) }

    it 'shows an access denied error' do
      expect(rendered).to have_css 'p', text: 'You do not appear to have ' \
        'permission to view any items in Argo. Please contact an administrator.'
    end
  end
end
