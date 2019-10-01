# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Release history' do
  before do
    sign_in create(:user), groups: ['sdr:administrator-role']
    allow(Dor::Config.workflow.client).to receive_messages(active_lifecycle: [], lifecycle: [])
  end

  it 'items show a release history' do
    visit solr_document_path 'druid:qq613vj0238'
    expect(page).to have_css 'dt', text: 'Releases'
    expect(page).to have_css 'table.table thead tr th', text: 'Release'
    expect(page).to have_css 'tr td', text: /SEARCHWORKS/
    expect(page).to have_css 'tr td', text: /pjreed/
  end

  it 'adminPolicy objects do not show release history' do
    visit solr_document_path 'druid:fg464dn8891'
    expect(page).not_to have_css 'dt', text: 'Releases'
  end
end
