require 'spec_helper'

RSpec.feature 'Consistent titles' do
  before do
    sign_in create(:user), groups: ['sdr:administrator-role']
  end

  let(:title) { 'Slides, IA 11, Geodesic Domes, Double Skin "Growth" House, N.C. State, 1953' }
  scenario 'catalog index views' do
    visit search_catalog_path f: { objectType_ssim: ['item'] }
    expect(page).to have_css '.index_title', text: '1. ' + title
  end
  scenario 'catalog show view' do
    visit solr_document_path 'druid:hj185vb7593'
    expect(page).to have_css 'h1', text: title
  end
end
