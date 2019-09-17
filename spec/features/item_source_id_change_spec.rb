# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Item source id change' do
  before do
    sign_in create(:user), groups: ['sdr:administrator-role']
    allow(Dor::StateService).to receive(:new).and_return(state_service)
  end

  describe 'when modification is not allowed' do
    let(:state_service) { instance_double(Dor::StateService, allows_modification?: false) }

    it 'cannot change the source id' do
      visit source_id_ui_item_path 'druid:kv840rx2720'
      fill_in 'new_id', with: 'sulair:newSource'
      click_button 'Update'
      expect(page).to have_css 'body', text: 'Object cannot be modified in ' \
        'its current state.'
    end
  end

  describe 'when modification is allowed' do
    let(:state_service) { instance_double(Dor::StateService, allows_modification?: true) }

    it 'changes the source id' do
      visit source_id_ui_item_path 'druid:kv840rx2720'
      fill_in 'new_id', with: 'sulair:newSource'
      click_button 'Update'
      expect(page).to have_css '.alert.alert-info', text: 'Source Id for ' \
        'druid:kv840rx2720 has been updated!'
      expect(state_service).to have_received(:allows_modification?).exactly(3).times
    end
  end
end
