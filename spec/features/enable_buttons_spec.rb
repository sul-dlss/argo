# frozen_string_literal: true

require 'spec_helper'

RSpec.feature 'Enable buttons' do
  before do
    sign_in create(:user), groups: ['sdr:administrator-role']

    @obj = double(
      Dor::Item,
      admin_policy_object: nil,
      allows_modification?: true,
      datastreams: {},
      can_manage_item?: true,
      catkey: nil,
      identityMetadata: double(ng_xml: Nokogiri::XML(''))
    )
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
