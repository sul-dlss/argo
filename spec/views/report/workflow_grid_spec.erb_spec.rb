# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'report/_workflow_grid', type: :view do
  let(:blacklight_config) { ReportController.blacklight_config }
  let(:query_params) { { controller: 'report', action: 'workflow_grid' } }
  let(:search_state) { Blacklight::SearchState.new(query_params, blacklight_config) }
  let(:workflow_client) { instance_double(Dor::Workflow::Client, workflow_template: template) }
  let(:template) do
    { 'processes' => [{ 'name' => 'descriptive-metadata', 'label' => 'Descriptive Metadata' }] }
  end

  before do
    allow(view).to receive(:search_state).and_return(search_state)
    allow(view).to receive(:blacklight_config).and_return(blacklight_config)
    allow(view).to receive(:has_search_parameters?).and_return(false)
    allow(Dor::Workflow::Client).to receive(:new).and_return(workflow_client)
    stub_template '_did_you_mean.html.erb' => ''
    stub_template '_constraints.html.erb'  => ''
    stub_template '_search_sidebar.html.erb' => ''
  end

  it 'displays all the workflow states' do
    @solr_response = {
      'response' => { 'docs' => [] },
      'facet_counts' => {
        'facet_fields' => { 'wf_wps_ssim' => ['accessionWF:descriptive-metadata:waiting', 500], 'wf_wsp_ssim' => [], 'wf_swp_ssim' => [] }
      }
    }
    assign(:response, Blacklight::Solr::Response.new(@solr_response, nil, {}))
    render
    expect(rendered).to have_selector('table td.count.waiting', text: '500')
  end
end
