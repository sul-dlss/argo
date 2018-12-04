# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApplicationHelper do
  describe '#views_to_switch' do
    it 'returns the view switchers' do
      helper.views_to_switch.each do |view|
        expect(view).to be_an ViewSwitcher
      end
    end
  end
  describe '#bulk_update_view?' do
    it 'checks params' do
      params = {}
      expect(helper.bulk_update_view?(params)).to be_falsey
      params['controller'] = 'report'
      expect(helper.bulk_update_view?(params)).to be_falsey
      params['action'] = 'bulk'
      expect(helper.bulk_update_view?(params)).to be_truthy
    end
  end
  describe '#catalog_view?' do
    it 'checks params' do
      params = {}
      expect(helper.catalog_view?(params)).to be_falsey
      params['controller'] = 'catalog'
      expect(helper.catalog_view?(params)).to be_truthy
    end
  end
  describe '#report_view' do
    it 'checks params' do
      params = {}
      expect(helper.report_view?(params)).to be_falsey
      params['controller'] = 'report'
      expect(helper.report_view?(params)).to be_falsey
      params['action'] = 'index'
      expect(helper.report_view?(params)).to be_truthy
    end
  end
  describe '#workflow_grid_view?' do
    it 'checks params' do
      params = {}
      expect(helper.workflow_grid_view?(params)).to be_falsey
      params['controller'] = 'report'
      expect(helper.workflow_grid_view?(params)).to be_falsey
      params['action'] = 'workflow_grid'
      expect(helper.workflow_grid_view?(params)).to be_truthy
    end
  end
  describe '#search_of_pids' do
    context 'when nil' do
      it 'returns an empty string' do
        expect(helper.search_of_pids(nil)).to eq ''
      end
    end
    context 'when a Blacklight::Search' do
      it 'adds a pids_only param' do
        search = Search.new
        search.query_params = { q: 'cool catz' }
        expect(helper.search_of_pids(search)).to include(q: 'cool catz', 'pids_only' => true)
      end
    end
  end
end
