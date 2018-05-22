require 'spec_helper'

RSpec.feature 'Item catkey change' do
  before do
    sign_in create(:user), groups: ['sdr:administrator-role']
  end

  feature 'when modification is not allowed' do
    scenario 'cannot change the catkey' do
      expect_any_instance_of(Dor::Item)
        .to receive(:allows_modification?).and_return(false)
      visit catkey_ui_item_path 'druid:kv840rx2720'
      fill_in 'new_catkey', with: '12345'
      click_button 'Update'
      expect(page).to have_css 'body', text: 'Object cannot be modified in ' \
        'its current state.'
    end
  end
  feature 'when modification is allowed' do
    scenario 'changes the catkey' do
      # things get squirrely when you have an expect_any_instance_of for a
      # method that gets called repeatedly on different instantiations of the
      # class.  but allow_any_instance_of works fine, so use that with a block
      # that keeps count manually and provides a return val for invocations
      # of Dor::Item#allows_modification?
      allows_mod_count = 0
      allow_any_instance_of(Dor::Item).to receive(:allows_modification?) do
        allows_mod_count += 1
        true
      end

      visit catkey_ui_item_path 'druid:kv840rx2720'
      fill_in 'new_catkey', with: '12345'
      click_button 'Update'
      expect(page).to have_css '.alert.alert-info', text: 'Catkey for ' \
        'druid:kv840rx2720 has been updated!'
      expect(allows_mod_count).to be > 1
    end
  end
end
