# frozen_string_literal: true

require 'rails_helper'

describe 'Indexer Backlog status', js: true do
  before do
    sign_in create(:user), groups: ['sdr:administrator-role']
  end

  it 'displays hyphen when not reachable' do
    visit root_path
    expect(page).to have_css 'li p.navbar-text', text: 'Indexer Backlog: -'
  end
  it 'displays count when response is integer' do
    expect_any_instance_of(IndexQueue).to receive(:depth).and_return 100
    visit root_path
    expect(page).to have_css 'li p.navbar-text', text: 'Indexer Backlog: 100'
  end
  it 'adds text-warning class when greater than 1000' do
    expect_any_instance_of(IndexQueue).to receive(:depth).and_return 1001
    visit root_path
    expect(page).to have_css 'li p.navbar-text', text: 'Indexer Backlog: 1001'
    expect(page).to have_css '.text-warning', text: '1001'
  end
end
