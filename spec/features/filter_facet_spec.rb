# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'More facet view', js: true do
  before do
    sign_in create(:user), groups: ['sdr:administrator-role']
  end

  it 'filter works correctly' do
    visit '/catalog/facet/nonhydrus_collection_title_ssim'

    filter_field = find_field(id: 'filterInput')
    expect(filter_field).not_to be_nil

    expect(page).to have_content('Annual report of the State Corporation Commission')
    filter_field.fill_in(with: 'foo')
    expect(page).not_to have_content('Annual report of the State Corporation Commission')
    filter_field.fill_in(with: 'report')
    expect(page).to have_content('Annual report of the State Corporation Commission')
    filter_field.fill_in(with: 'druid:foo')
    expect(page).not_to have_content('druid:pb873ty1662')
  end
end
