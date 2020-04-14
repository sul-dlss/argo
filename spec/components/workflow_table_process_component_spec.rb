# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkflowTableProcessComponent, type: :component do
  subject(:component) { described_class.new(workflow_table_process: [process, 'desc'], name: name, data: data) }

  describe '#workflow_reset_link' do
    subject { component.workflow_reset_link(status) }

    let(:name) { 'accessionWF' }
    let(:process) { 'descriptive-metadata' }
    let(:status) { 'error' }
    let(:blacklight_config) { Blacklight::Configuration.new }
    let(:query_params) { { controller: 'report', action: 'workflow_grid' } }
    let(:search_state) { Blacklight::SearchState.new(query_params, blacklight_config) }

    before do
      #    allow(component.view_context).to receive(:blacklight_config).and_return blacklight_config
      allow(component).to receive(:search_state).and_return search_state
      allow(component).to receive(:report_reset_path).and_return('/foo')
    end

    describe 'wf_hash structure' do
      context 'without process' do
        let(:data) { {} }

        it { is_expected.to be_nil }
      end

      context 'without status' do
        let(:data) { { process => {} } }

        it { is_expected.to be_nil }
      end

      context 'without trailing _' do
        let(:data) { { process => { status => {} } } }

        it { is_expected.to be_nil }
      end

      context 'with all' do
        let(:data) do
          { process =>
            { status => { _: Blacklight::Solr::Response::Facets::FacetItem.new(hits: 4) } } }
        end
        let(:body) { render_inline(component) }

        it 'has a link' do
          expect(body.css('a[data-remote="true"][rel="nofollow"][data-method="post"]', text: 'reset')).to be_present
        end
      end
    end
  end
end
