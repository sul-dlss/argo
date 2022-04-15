# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Draw a list of bulk actions' do
  let(:user) { create(:user) }
  let(:rendered) do
    Capybara::Node::Simple.new(response.body)
  end

  before do
    BulkAction.create!(action_type: 'ExportTagsJob', status: 'Completed', user:)
    BulkAction.create!(action_type: 'ChecksumReportJob', status: 'Completed', user:)
    BulkAction.create!(action_type: 'RegisterDruidsJob', status: 'Completed', user:)
    allow_any_instance_of(BulkAction).to receive(:has_report?).and_return(true)
  end

  it 'authorizes the view' do
    sign_in user, groups: ['sdr:administrator-role']
    get '/bulk_actions'
    expect(response).to have_http_status(:success)
    expect(rendered).to have_link 'New Bulk Action'
    expect(rendered).to have_link 'Download Exported Tags (CSV)'
    expect(rendered).to have_link 'Download Checksum Report'
    expect(rendered).to have_link 'Download Report'
  end
end
