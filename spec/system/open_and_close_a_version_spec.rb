# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Open and close a version' do
  let(:item) do
    FactoryBot.create_for_repository(:persisted_item)
  end

  let(:workflow_client) { Dor::Services::Client.object(item.externalIdentifier).workflow('accessionWF') }
  let(:accession_processes) { Dor::Services::Client.workflows.template('accessionWF').fetch('processes').pluck('name') }

  before do
    VersionService.close(druid: item.externalIdentifier)
    # This kicks off the accessionWF workflow. However, there are no robots so it
    # will not complete. We need to manually complete each step below.
    sign_in create(:user), groups: ['sdr:administrator-role']
  end

  it 'opens an object', :js do
    # Manually complete the accessionWF steps to allow the object to be openable.
    visit solr_document_path item.externalIdentifier
    # Ensure every step of accessionWF is completed, this will allow us to open a new version.
    accession_processes.each do |process|
      workflow_client.process(process).update(status: 'completed')
    end
    click_link 'Reindex'

    sleep 0.5 until VersionService.openable?(druid: item.externalIdentifier)

    accept_alert do # For an unknown reason, sometimes a network error occurs here which triggers the refresh alert.
      visit solr_document_path item.externalIdentifier
    end
    click_link 'Unlock to make changes to this object'
    fill_in 'Version description', with: 'Test a change'

    click_button 'Open Version'
    expect(page).to have_content "#{item.externalIdentifier} is open for modification!"

    click_link 'Close Version'
    expect(page).to have_content 'Test a change'

    click_button 'Close Version'

    expect(page).to have_content "Version 2 of #{item.externalIdentifier} has been closed!"
  end
end
