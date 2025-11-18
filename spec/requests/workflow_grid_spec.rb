# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Display the workflow grid' do
  let(:rendered) do
    Capybara::Node::Simple.new(response.body)
  end
  let(:user) { create(:user) }
  let(:service) { instance_double(Blacklight::SearchService, search_results: [results, nil]) }
  let(:results) { Blacklight::Solr::Response.new(solr_response, nil, {}) }
  let(:solr_response) do
    {
      'response' => { 'docs' => [] },
      'facet_counts' => {
        'facet_fields' => { SolrDocument::FIELD_WORKFLOW_WPS => ['accessionWF:publish:waiting', 500] }
      }
    }
  end

  before do
    sign_in user, groups: ['sdr:administrator-role']
    allow(Blacklight::SearchService).to receive(:new).and_return(service)
  end

  it 'draws the grid' do
    get '/report/workflow_grid', headers: { 'X-Requester' => 'frontend' }
    expect(response).to be_successful
    expect(rendered).to have_css('table td.count.waiting', text: '500')
  end
end
