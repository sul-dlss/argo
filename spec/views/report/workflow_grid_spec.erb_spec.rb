require 'spec_helper'

describe 'report/workflow_grid', :type => :view do
  before do
    allow(view).to receive(:content_for).with(:head).and_return([])
    allow(view).to receive(:blacklight_config).and_return(ReportController.blacklight_config)
    allow(view).to receive(:has_search_parameters?).and_return(false)
    stub_template '_did_you_mean.html.erb' => ''
    stub_template '_constraints.html.erb'  => ''
    stub_template '_search_sidebar.html.erb'       => ''
  end
  it "should display all the workflow states" do
    @solr_response = { 'response' => { 'docs' => [] }, 'facet_counts' => { 'facet_fields' => { 'wf_wps_ssim' => ['accessionWF:descriptive-metadata:waiting', 500], 'wf_wsp_ssim' => [], 'wf_swp_ssim' => []} } }
    assign(:response, RSolr::Ext::Response::Base.new(@solr_response, nil, {}))
    render
    expect(rendered).to have_selector('table td.count.waiting', :text => '500')
  end
end
