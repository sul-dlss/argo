# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkflowTableProcessComponent, type: :component do
  subject(:component) { described_class.new(workflow_table_process: [process, 'desc'], name:, data:) }

  describe '#workflow_reset_link' do
    subject { component.workflow_reset_link(status) }

    let(:name) { 'accessionWF' }
    let(:process) { 'descriptive-metadata' }
    let(:status) { 'error' }
    let(:blacklight_config) do
      Blacklight::Configuration.new.configure do |config|
        config.facet_display = {
          hierarchy: {
            'wf_wps' => [['ssim'], ':'],
            'wf_wsp' => [['ssim'], ':'],
            'wf_swp' => [['ssim'], ':'],
            'exploded_nonproject_tag' => [['ssim'], ':'],
            'exploded_project_tag' => [['ssim'], ':']
          }
        }
      end
    end
    let(:query_params) { { controller: 'report', action: 'workflow_grid' } }
    let(:search_state) { Blacklight::SearchState.new(query_params, blacklight_config) }

    before do
      allow(component).to receive_messages(search_state:, report_reset_path: '/foo')
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
          expect(body.css('.btn.btn-link', text: 'reset')).to be_present
        end
      end
    end
  end
end
