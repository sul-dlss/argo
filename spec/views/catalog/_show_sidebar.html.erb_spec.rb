# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'catalog/_show_sidebar.html.erb' do
  let(:document) do
    SolrDocument.new(id: 'druid:abc123')
  end
  let(:current_user) { mock_user }

  before do
    config = Blacklight::Configuration.new
    allow(view).to receive(:blacklight_config).and_return(config)
    allow(view).to receive(:current_user).and_return(current_user)
    allow(controller).to receive(:current_user).and_return(current_user)
    @document = document
  end

  it 'renders a list of links' do
    allow(view).to receive(:render).and_call_original
    allow(view).to receive(:render).with(ExternalLinksComponent).and_return('')
    render
    expect(rendered).to have_css '.show_sidebar'
  end
end
