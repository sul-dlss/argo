require 'spec_helper'

feature 'Enable buttons' do
  before do
    @current_user = mock_user(is_admin?: true)
    @obj = double(
      'item',
      admin_policy_object: false,
      datastreams: {},
      can_manage_item?: true,
      identityMetadata: double(ng_xml: Nokogiri::XML(''))
    )
    allow_any_instance_of(ApplicationController).to receive(:current_user).
      and_return(@current_user)
    allow(Dor).to receive(:find).and_return(@obj)
  end
  scenario 'buttons are disabled by default that have check_url' do
    visit solr_document_path 'druid:hj185vb7593'
    expect(page).to have_css 'a.disabled', text: 'Close Version'
    expect(page).to have_css 'a.disabled', text: 'Open for modification'
    expect(page).to have_css 'a.disabled', text: 'Republish'
  end
  scenario 'buttons are enabled if their services return true', js: true do
    allow_any_instance_of(WorkflowServiceController).to receive(:check_if_can_close_version).and_return(true)
    allow_any_instance_of(WorkflowServiceController).to receive(:check_if_can_open_version).and_return(true)
    allow_any_instance_of(WorkflowServiceController).to receive(:check_if_published).and_return(true)
    visit solr_document_path 'druid:hj185vb7593'
    expect(page).to_not have_css 'a.disabled', text: 'Close Version'
    expect(page).to_not have_css 'a.disabled', text: 'Open for modification'
    expect(page).to_not have_css 'a.disabled', text: 'Republish'
  end
end
