require 'spec_helper'

describe 'report/workflow_grid' do
  before do
    view.stub(:extra_head_content).and_return([])
    view.stub(:blacklight_config).and_return(ReportController.blacklight_config)
    stub_template '_search_form' => '', '_did_you_mean' => '', '_constraints' => '', '_facets' => ''
  end
  it "should display all the workflow states" do
    @solr_response = { 'response' => { 'docs' => [] }, 'facet_counts' => { 'facet_fields' => { 'wf_wps_facet' => ['accessionWF:cleanup:waiting', 500], 'wf_wsp_facet' => [], 'wf_swp_facet' => []} } }
    assign(:response, RSolr::Ext::Response::Base.new(@solr_response, nil, {}))

    render
  end
end
