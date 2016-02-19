require 'spec_helper'

RSpec.describe 'catalog/_show_embargo_sidebar.html.erb' do
  before(:each) do
    assign(:document, document)
  end
  context 'embargoed with release date' do
    let(:document) do
      SolrDocument.new(
        id: 1,
        SolrDocument::FIELD_EMBARGO_STATUS => ['embargoed'],
        SolrDocument::FIELD_EMBARGO_RELEASE_DATE => ['24/02/2259']
      )
    end
    it 'displays release date' do
      render
      expect(rendered).to have_css '.panel-heading h3', text: 'Embargo'
      expect(rendered).to have_css '.panel-body', text: 'This item is ' \
        'embargoed until 2259.02.24'
    end
  end
  context 'embargoed without release date' do
    let(:document) do
      SolrDocument.new(
        id: 1,
        SolrDocument::FIELD_EMBARGO_STATUS => ['embargoed']
      )
    end
    it 'does not render anything' do
      render
      expect(rendered.strip).to eq ''
    end
  end
  context 'not embargoed with release date' do
    let(:document) do
      SolrDocument.new(
        id: 1,
        SolrDocument::FIELD_EMBARGO_STATUS => ['strange occurrence'],
        SolrDocument::FIELD_EMBARGO_RELEASE_DATE => ['24/02/2259']
      )
    end
    it 'does not render anything' do
      render
      expect(rendered.strip).to eq ''
    end
  end
end
