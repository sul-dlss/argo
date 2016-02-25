require 'spec_helper'

feature 'Workflow Service Creation' do
  let(:item) do
    object = instantiate_fixture('hj185vb7593', Dor::Item)
    allow(Dor::Item).to receive(:find).with(object.pid).and_return(object)
    object
  end
  before :each do
    @current_user = admin_user # see spec_helper
  end
  scenario 'redirect and display on show page' do
    expect(item).to receive(:create_workflow).and_return(true)
    visit add_workflow_item_path item.pid
    click_button 'Add'
    within '.flash_messages' do
      expect(page).to have_css '.alert.alert-info', text: 'Added accessionWF'
    end
  end
end
