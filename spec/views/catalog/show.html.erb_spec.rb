require 'spec_helper'

RSpec.describe 'catalog/show.html.erb' do
  let(:document) do
    SolrDocument.new(
      id: 1,
      dc_title_ssi: 'Long title that should be truncated at 50 characters'
    )
  end
  before(:each) do
    @config = Blacklight::Configuration.new do |config|
      config.index.title_field = 'dc_title_ssi'
    end
    allow(view).to receive(:blacklight_config).and_return(@config)
    assign(:document, document)
  end
  it 'assigns page title, truncating it' do
    expect(view).to receive(:render_document_sidebar_partial)
    expect(view).to receive(:item_page_entry_info)
    expect(view).to receive(:render_document_partial)
    expect(view).to receive(:current_search_session)
    render
    expect(view.instance_variable_get(:@page_title))
      .to eq 'Long title that should be truncated at 50 chara... - Argo'
  end
end
