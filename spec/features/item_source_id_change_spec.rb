require 'spec_helper'

feature 'Item source id change' do
  before :each do
    admin_user # see spec_helper
  end

  feature 'when modification is not allowed' do
    scenario 'cannot change the source id' do
      expect_any_instance_of(Dor::Item)
        .to receive(:allows_modification?).and_return(false)
      visit source_id_ui_item_path 'druid:kv840rx2720'
      fill_in 'new_id', with: 'sulair:newSource'
      click_button 'Update'
      expect(page).to have_css 'body', text: 'Object cannot be modified in ' \
        'its current state.'
    end
  end

  feature 'when modification is allowed' do
    scenario 'changes the source id' do
      expect_any_instance_of(Dor::Item)
        .to receive(:allows_modification?).and_return(true)
      visit source_id_ui_item_path 'druid:kv840rx2720'
      fill_in 'new_id', with: 'sulair:newSource'
      click_button 'Update'
      expect(page).to have_css '.alert.alert-info', text: 'Source Id for ' \
        'druid:kv840rx2720 has been updated!'
    end
  end
end
