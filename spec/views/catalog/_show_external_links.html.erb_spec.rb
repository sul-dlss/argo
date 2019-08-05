# frozen_string_literal: true

require 'rails_helper'

describe 'catalog/_show_external_links.html.erb' do
  let(:document) do
    SolrDocument.new(id: 'druid:abc123', catkey_id_ssim: 'catz')
  end
  let(:current_user) { mock_user }

  let(:object) { instance_double(Dor::Item) }

  before do
    config = Blacklight::Configuration.new
    allow(view).to receive(:blacklight_config).and_return(config)
    allow(view).to receive(:current_user).and_return(current_user)
    allow(controller).to receive(:current_user).and_return(current_user)
  end

  it 'renders link list' do
    expect(view).to receive(:render_buttons).with(document, object).and_return({})
    render 'catalog/show_external_links', document: document, object: object
    expect(rendered).to have_css '.show_sidebar'
    expect(rendered).to have_css 'ul.nav.nav-stacked'
    expect(rendered).to have_css 'li', count: 6
    expect(rendered).to have_css 'a[href="/view/druid:abc123.json"]', text: 'Solr document'
  end
end
