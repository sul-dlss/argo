require 'spec_helper'

describe 'catalog/_show_releases.html.erb' do
  describe 'creates a table of release information' do
    let(:release_tags) { [['SEARCHWORKS', [{'what' => 'self', 'when' => '2016-09-13 20:00:00 UTC', 'who' => 'pjreed', 'release' => true}]]] }
    let(:object) { double(pid: 'druid:qq613vj0238', release_tags: release_tags) }
    before do
      allow(view).to receive(:object).and_return(object)
    end
    it 'displays a table of release tags' do
      render
      expect(rendered).to have_css 'table.table'
      expect(rendered).to have_css 'tbody td:nth-child(1)', text: 'true'
      expect(rendered).to have_css 'tbody td:nth-child(2)', text: 'self'
      expect(rendered).to have_css 'tbody td:nth-child(3)', text: 'SEARCHWORKS'
      expect(rendered).to have_css 'tbody td:nth-child(4)', text: 'pjreed'
      expect(rendered).to have_css 'tbody td:nth-child(5)', text: '2016-09-13 20:00:00 UTC'
    end
  end
end
