# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'More facet view', js: true do
  before do
    ActiveFedora::SolrService.add(id: 'druid:xb482bw3983',
                                  nonhydrus_collection_title_ssim: 'Annual report of the State Corporation Commission')
    ActiveFedora::SolrService.commit
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
  end
end
