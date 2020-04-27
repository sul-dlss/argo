# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Report view' do
  before do
    sign_in create(:user), groups: ['sdr:administrator-role']
  end

  describe 'the show page', js: true do
    it 'shows table without error' do
      visit report_path f: { objectType_ssim: ['item'] }
      expect(page).to have_css 'table#report_grid'
      expect(page).to have_content('hj185vb7593')
    end

    it 'shows the column selector when clicked' do
      visit report_path f: { objectType_ssim: ['item'] }
      find('.ui-pg-button-text', text: 'Columns').click
      expect(page).to have_css 'div#column_selector'
      expect(page).to have_content('Select columns to download:')
      expect(page).to have_selector('input[name="selected_columns"]', count: 26) # count the total
      expect(page).to have_selector('input[name="selected_columns"]:checked', count: 5) # count the default
    end
  end

  context 'bulk' do
    before do
      allow(Dor::Workflow::Client).to receive(:new).and_return(workflow_client)
    end

    let(:workflow_client) { instance_double(Dor::Workflow::Client, workflow_templates: []) }

    it 'returns a page with the expected elements' do
      visit '/report/bulk'
      expect(page).to have_content('Bulk update operations')
      expect(page).to have_css('.bulk_button', text: 'Get druids from search')
      expect(page).to have_css('.bulk_button', text: 'Paste a druid list')
    end
  end
end
