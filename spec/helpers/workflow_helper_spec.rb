require 'spec_helper'

describe WorkflowHelper, type: :helper do
  describe '#render_workflow_reset_link' do
    let(:name) { 'accessionWF' }
    let(:process) { 'descriptive-metadata' }
    let(:status) { 'error' }
    let(:blacklight_config) { Blacklight::Configuration.new }
    let(:query_params) { { controller: 'report', action: 'workflow_grid' } }
    let(:search_state) { Blacklight::SearchState.new(query_params, blacklight_config) }
    before(:each) do
      allow(helper).to receive(:blacklight_config).and_return blacklight_config
      allow(helper).to receive(:search_state).and_return search_state
    end
    describe 'wf_hash structure' do
      it 'without process' do
        wf_hash = {}
        expect(helper
          .render_workflow_reset_link(wf_hash, name, process, status)).to be_nil
      end
      it 'without status' do
        wf_hash = { process => {} }
        expect(helper
          .render_workflow_reset_link(wf_hash, name, process, status)).to be_nil
      end
      it 'without trailing _' do
        wf_hash = { process => { status => {} } }
        expect(helper
          .render_workflow_reset_link(wf_hash, name, process, status)).to be_nil
      end
      it 'with all' do
        wf_hash = { process => { status => { _: '' } } }
        expect(helper
          .render_workflow_reset_link(wf_hash, name, process, status))
          .to_not be_nil
      end
    end
    describe 'reset link' do
      it '' do
        wf_hash = { process => { status => { _: '' } } }
        link = helper.render_workflow_reset_link(wf_hash, name, process, status)
        expect(link).to have_css 'a[data-remote="true"][rel="nofollow"]' \
          '[data-method="post"]', text: 'reset'
      end
    end
  end
end
