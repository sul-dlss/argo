require 'spec_helper'

describe 'catalog/_show_external_links.html.erb' do
  let(:document) do
    SolrDocument.new(id: 'druid:abc123', catkey_id_ssim: 'catz')
  end
  let(:current_user) { double('current_user', is_admin: false) }
  before(:each) do
    config = Blacklight::Configuration.new
    allow(view).to receive(:blacklight_config).and_return(config)
    assign(:document, document)
  end
  it 'renders link list' do
    expect(view).to receive(:current_user).and_return(current_user)
    expect(view).to receive(:render_buttons).and_return({})
    render
    expect(rendered).to have_css '.show_sidebar'
    expect(rendered).to have_css 'ul.nav.nav-stacked'
    expect(rendered).to have_css 'li', count: 6
  end
end
