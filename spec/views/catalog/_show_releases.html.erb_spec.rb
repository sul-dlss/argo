# frozen_string_literal: true

require 'spec_helper'

describe 'catalog/_show_releases.html.erb' do
  describe 'creates a table of release information' do
    let(:object) { instantiate_fixture('druid:qq613vj0238') }

    before do
      allow(view).to receive(:object).and_return(object)
    end

    it 'displays a table of release tags' do
      render
      expect(rendered).to have_css 'table.table'
      expect(rendered).to have_css 'tbody td:nth-child(1)', text: 'true'
      expect(rendered).to have_css 'tbody td:nth-child(2)', text: 'self', count: 2
      expect(rendered).to have_css 'tbody td:nth-child(3)', text: 'SEARCHWORKS', count: 2
      expect(rendered).to have_css 'tbody td:nth-child(4)', text: 'pjreed', count: 2
      expect(rendered).to have_css 'tbody td:nth-child(5)', text: '2016-09-13T20:00:00.000Z'
    end
  end
end
