require 'spec_helper'

describe WorkflowHelper, :type => :helper do 
  describe 'render_workflow_archive_count' do
    it 'should render the count if there is one' do
      wf_name = "testWF"
      query_params = "objectType_ssim:workflow title_tesim:#{wf_name}"
      archived_disp_count = 42
      query_results = double('query_results', :docs => [{"#{wf_name}_archived_isi" => archived_disp_count}])

      allow(Dor::SearchService).to receive(:query).with(query_params).and_return(query_results)
      result = render_workflow_archive_count(nil, wf_name)
      expect(result).to eq(archived_disp_count)
    end
    it 'should return hyphen if it cannot get query results' do
      wf_name = "testWF"
      query_params = "objectType_ssim:workflow title_tesim:#{wf_name}"
      query_results = nil

      allow(Dor::SearchService).to receive(:query).with(query_params).and_return(query_results)
      result = render_workflow_archive_count(nil, wf_name)
      expect(result).to eq("-")
    end
    it 'should return hyphen if it cannot get a count from query results' do
      wf_name = "testWF"
      query_params = "objectType_ssim:workflow title_tesim:#{wf_name}"
      query_results = double('query_results', :docs => [{'wrong_field' => 'wrong value'}])

      allow(Dor::SearchService).to receive(:query).with(query_params).and_return(query_results)
      result = render_workflow_archive_count(nil, wf_name)
      expect(result).to eq("-")
    end
  end
end