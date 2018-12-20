# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Workflow Service Creation' do
  before do
    sign_in create(:user), groups: ['sdr:administrator-role']
  end

  it 'redirect and display on show page' do
    visit add_workflow_item_path 'druid:qq613vj0238'
    click_button 'Add'
    within '.flash_messages' do
      expect(page).to have_css '.alert.alert-info', text: 'Added accessionWF'
    end
    expect(page).to have_css 'tr td a', text: 'accessionWF'
  end
end
