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
  describe '#discovery_view?' do
    it 'checks params' do
      params = {}
      expect(helper.discovery_view?(params)).to be_falsey
      params['controller'] = 'discovery'
      expect(helper.discovery_view?(params)).to be_truthy
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
end
