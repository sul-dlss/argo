# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'More facet view', :js do
  let(:blacklight_config) { CatalogController.blacklight_config }
  let(:solr_conn) { blacklight_config.repository_class.new(blacklight_config).connection }

  before do
    solr_conn.add(id: 'druid:xb482bw3983',
                  SolrDocument::FIELD_COLLECTION_TITLE => 'Annual report of the State Corporation Commission')
    solr_conn.commit
    sign_in create(:user), groups: ['sdr:administrator-role']
  end

  it 'filter works correctly' do
    visit "/catalog/facet/#{SolrDocument::FIELD_COLLECTION_TITLE}"

    filter_field = find_field(id: 'filterInput')
    expect(filter_field).not_to be_nil

    expect(page).to have_content('Annual report of the State Corporation Commission')
    filter_field.fill_in(with: 'foo')
    expect(page).to have_no_content('Annual report of the State Corporation Commission')
    filter_field.fill_in(with: 'report')
    expect(page).to have_content('Annual report of the State Corporation Commission')
  end
end
