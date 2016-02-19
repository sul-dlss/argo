require 'spec_helper'

describe WorkflowHelper, :type => :helper do
  describe 'render_workflow_archive_count' do
    it 'should render the count if there is one' do
      wf_name = 'testWF'
      query_params = "objectType_ssim:workflow title_tesim:#{wf_name}"
      archived_disp_count = 42
      query_results = double('query_results', :docs => [{"#{wf_name}_archived_isi" => archived_disp_count}])

      allow(Dor::SearchService).to receive(:query).with(query_params).and_return(query_results)
      result = render_workflow_archive_count(nil, wf_name)
      expect(result).to eq(archived_disp_count)
    end
    it 'should return hyphen if it cannot get query results' do
      wf_name = 'testWF'
      query_params = "objectType_ssim:workflow title_tesim:#{wf_name}"
      query_results = nil

      allow(Dor::SearchService).to receive(:query).with(query_params).and_return(query_results)
      result = render_workflow_archive_count(nil, wf_name)
      expect(result).to eq('-')
    end
    it 'should return hyphen if it cannot get a count from query results' do
      wf_name = 'testWF'
      query_params = "objectType_ssim:workflow title_tesim:#{wf_name}"
      query_results = double('query_results', :docs => [{'wrong_field' => 'wrong value'}])

      allow(Dor::SearchService).to receive(:query).with(query_params).and_return(query_results)
      result = render_workflow_archive_count(nil, wf_name)
      expect(result).to eq('-')
    end
  end
  describe '#render_workflow_reset_link' do
    let(:name) { 'accessionWF' }
    let(:process) { 'descriptive-metadata' }
    let(:status) { 'error' }
    let(:blacklight_config) { Blacklight::Configuration.new }
    before(:each) do
      allow(helper).to receive(:blacklight_config).and_return blacklight_config
    end
    describe 'wf_hash structure' do
      it 'without process' do
        wf_hash = {}
        expect(helper
          .render_workflow_reset_link(wf_hash, name, process, status)).to be_nil
      end
      it 'without status' do
        wf_hash = { process => {}}
        expect(helper
          .render_workflow_reset_link(wf_hash, name, process, status)).to be_nil
      end
      it 'without trailing _' do
        wf_hash = { process => { status => { }}}
        expect(helper
          .render_workflow_reset_link(wf_hash, name, process, status)).to be_nil
      end
      it 'with all' do
        wf_hash = { process => { status => { _: '' } }}
        expect(helper
          .render_workflow_reset_link(wf_hash, name, process, status))
            .to_not be_nil
      end
    end
    describe 'reset link' do
      it '' do
        wf_hash = { process => { status => { _: '' } }}
        link = helper.render_workflow_reset_link(wf_hash, name, process, status)
        expect(link).to have_css 'a[data-remote="true"][rel="nofollow"]' \
          '[data-method="post"]', text: 'reset'
      end
    end
  end
end
