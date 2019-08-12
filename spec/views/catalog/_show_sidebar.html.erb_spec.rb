# frozen_string_literal: true

require 'rails_helper'

describe 'catalog/_show_sidebar.html.erb' do
  let(:document) do
    SolrDocument.new(id: 'druid:abc123', catkey_id_ssim: 'catz')
  end
  let(:current_user) { mock_user }
  let(:button_presenter) {  }

  before do
    config = Blacklight::Configuration.new
    allow(view).to receive(:blacklight_config).and_return(config)
    allow(view).to receive(:current_user).and_return(current_user)
    allow(controller).to receive(:current_user).and_return(current_user)
    @document = document
    @buttons_presenter = instance_double(ButtonsPresenter, buttons: [])
  end

  it 'renders a list of links' do
    render
    expect(rendered).to have_css '.show_sidebar'
    expect(rendered).to have_css 'ul.nav.nav-stacked'
    expect(rendered).to have_css 'li', count: 6
    expect(rendered).to have_css 'a[href="/view/druid:abc123.json"]', text: 'Solr document'
  end
end
