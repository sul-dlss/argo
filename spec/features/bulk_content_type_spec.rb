# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Bulk set content type', :js do
  let(:current_user) { create(:user) }
  let(:bulk_action) { instance_double(BulkAction, save: true, enqueue_job: nil) }

  before do
    allow(BulkAction).to receive(:new).and_return(bulk_action)
    sign_in current_user
  end

  it 'Creates a new jobs' do
    visit new_bulk_action_path
    select 'Set content type'
    select 'file', from: 'Current resource type'
    select 'book', from: 'New content type'
    select 'right-to-left', from: 'Viewing direction'
    select 'image', from: 'New resource type'
    fill_in 'Druids to perform bulk action on', with: 'druid:ab123gg7777'
    click_button 'Submit'
    expect(page).to have_css 'h1', text: 'Bulk Actions'

    expect(bulk_action).to have_received(:enqueue_job).with(current_resource_type: 'https://cocina.sul.stanford.edu/models/resources/file',
                                                            druids: ['druid:ab123gg7777'],
                                                            groups: current_user.groups,
                                                            new_content_type: 'https://cocina.sul.stanford.edu/models/book',
                                                            new_resource_type: 'https://cocina.sul.stanford.edu/models/resources/image',
                                                            viewing_direction: 'right-to-left')
  end
end
