# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Bulk Update of Governing APO' do
  let(:current_user) { create(:user) }

  before do
    sign_in current_user
    allow_any_instance_of(RegistrationHelper).to receive(:apo_list).and_return(['APO 1', 'APO 2', 'APO 3'])
  end

  it 'Creates a new job' do
    visit new_bulk_action_path
    select 'Update governing APO'
    select 'APO 2'
    fill_in 'pids', with: 'druid:br481xz7820'
    click_button 'Submit'
    expect(page).to have_css 'h1', text: 'Bulk Actions'
    within 'table.table' do
      expect(page).to have_css 'td', text: 'SetGoverningApoJob'
      expect(page).to have_css 'td', text: 'Processing'
    end
  end
end
