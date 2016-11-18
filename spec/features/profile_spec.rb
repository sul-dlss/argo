require 'spec_helper'

describe 'Profile' do
  let(:current_user) do
    mock_user(is_admin?: true)
  end
  before do
    expect_any_instance_of(ProfileController).to receive(:current_user)
      .at_least(1).times.and_return(current_user)
  end
  describe 'Admin Policies' do
    it 'lists admin policies and counts' do
      visit search_profile_path f: { objectType_ssim: ['item'] }
      within '#admin-policies' do
        expect(page).to have_css 'h4', text: 'Admin Policies'
        expect(page).to have_css 'td:nth-child(1)', text: 'Stanford University Libraries - Special Collections'
        expect(page).to have_css 'td:nth-child(2)', text: '4'
      end
    end
  end
  describe 'Collection' do
    it 'lists collections and counts' do
      visit search_profile_path f: { objectType_ssim: ['item'] }
      within '#collection' do
        expect(page).to have_css 'h4', text: 'Collection'
        expect(page).to have_css 'td:nth-child(1)', text: 'druid:pb873ty1662'
        expect(page).to have_css 'td:nth-child(2)', text: '1'
      end
    end
  end
  describe 'Discovery' do
    it 'lists discovery and counts' do
      visit search_profile_path f: { objectType_ssim: ['item'] }
      within '#discovery' do
        expect(page).to have_css 'h4', text: 'Discovery'
        expect(page).to have_css 'td:nth-child(1)', text: 'Published to PURL'
        expect(page).to have_css 'td:nth-child(2)', text: '0'
        expect(page).to have_css 'td:nth-child(1)', text: 'SEARCHWORKS'
        expect(page).to have_css 'h5', text: 'Catkeys'
        expect(page).to have_css 'td:nth-child(1)', text: 'has value'
        expect(page).to have_css 'td:nth-child(2)', text: '2'
      end
    end
  end
  describe 'Rights' do
    it 'lists rights and counts' do
      visit search_profile_path f: { objectType_ssim: ['item'] }
      within '#rights' do
        expect(page).to have_css 'h4', text: 'Rights'
        expect(page).to have_css 'td:nth-child(1)', text: 'dark'
        expect(page).to have_css 'td:nth-child(2)', text: '2'
      end
    end
  end
  describe 'Contents' do
    it 'lists content type and counts' do
      visit search_profile_path f: { objectType_ssim: ['item'] }
      within '#contents' do
        expect(page).to have_css 'h4', text: 'Contents'
        expect(page).to have_css 'td:nth-child(1)', text: 'image'
        expect(page).to have_css 'td:nth-child(2)', text: '3'
        expect(page).to have_css 'td:nth-child(1)', text: 'Preserved file size'
        expect(page).to have_css 'td:nth-child(2)', text: '160 MB'
      end
    end
  end
  describe 'Rights information' do
    it 'lists rights information and counts' do
      visit search_profile_path f: { objectType_ssim: ['item'] }
      within '#rights-information' do
        expect(page).to have_css 'h4', text: 'Rights information'
        expect(page).to have_css 'h5', text: 'Use & Reproduction'
        expect(page).to have_css 'h5', text: 'Copyright'
        expect(page).to have_css 'h5', text: 'License'
        expect(page).to have_css 'td:nth-child(1)', text: /govinfolib@lists.stanford.edu/
        expect(page).to have_css 'td:nth-child(2)', text: '3'
        expect(page).to have_css 'td:nth-child(1)', text: 'Copyright © Stanford University. All Rights Reserved.'
        expect(page).to have_css 'td:nth-child(2)', text: '1'
      end
    end
  end
  describe 'SearchWorks facet values' do
    it 'lists content type and counts' do
      visit search_profile_path f: { objectType_ssim: ['item'] }
      within '#searchworks-facet-values' do
        expect(page).to have_css 'h4', text: 'SearchWorks facet values'
        expect(page).to have_css 'h5', text: 'Resource Type'
        expect(page).to have_css 'h5', text: 'Date'
        expect(page).to have_css 'h5', text: 'Language'
        expect(page).to have_css 'h5', text: 'Topic'
        expect(page).to have_css 'h5', text: 'Region'
        expect(page).to have_css 'h5', text: 'Era'
        expect(page).to have_css 'h5', text: 'Genre'
        expect(page).to have_css 'td:nth-child(1)', text: 'Image'
        expect(page).to have_css 'td:nth-child(2)', text: '3'
        expect(page).to have_css 'td:nth-child(1)', text: 'has value'
        expect(page).to have_css 'td:nth-child(2)', text: '2'
        expect(page).to have_css 'td:nth-child(1)', text: 'English'
        expect(page).to have_css 'td:nth-child(2)', text: '2'
        expect(page).to have_css 'td:nth-child(1)', text: 'Cephalopoda'
        expect(page).to have_css 'td:nth-child(2)', text: '1'
        expect(page).to have_css 'td:nth-child(1)', text: 'Bermuda Islands'
        expect(page).to have_css 'td:nth-child(2)', text: '1'
      end
    end
  end
  describe 'Number of items' do
    it 'lists object type and pivot facets' do
      visit search_profile_path f: { exploded_tag_ssim: ['Project'] }
      within '#number-of-items' do
        expect(page).to have_css 'h4', text: 'Number of items'
        expect(page).to have_css 'td:nth-child(1)', text: 'item'
        expect(page).to have_css 'td:nth-child(2)', text: '6'
        expect(page).to have_css 'td.indented:nth-child(1)', text: 'Unknown Status'
        expect(page).to have_css 'td:nth-child(2)', text: '4'
      end
    end
  end
end
