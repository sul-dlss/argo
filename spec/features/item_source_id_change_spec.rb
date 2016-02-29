require 'spec_helper'

RSpec.feature 'Item source id change' do
  let(:current_user) do
    mock_user(is_admin?: true)
  end
  before do
    allow_any_instance_of(ItemsController).to receive(:current_user)
      .and_return(current_user)
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
      expect_any_instance_of(CatalogController).to receive(:current_user)
        .at_least(1).times.and_return(current_user)
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
