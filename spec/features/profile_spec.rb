# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Profile' do
  before do
    ActiveFedora::SolrService.add(id: 'druid:xb482bw3979',
                                  objectType_ssim: 'item',
                                  topic_ssim: 'Cephalopoda',
                                  sw_subject_geographic_ssim: 'Bermuda Islands',
                                  tag_ssim: ['Project : Argo Demo', 'Registered By : mbklein'])
    ActiveFedora::SolrService.commit
    sign_in create(:user), groups: ['sdr:administrator-role']
  end

  it 'displays a profile of the result set' do
    visit search_profile_path f: { objectType_ssim: ['item'] }
    within '#admin-policies' do
      expect(page).to have_css 'h4', text: 'Admin Policies'
      expect(page).to have_css 'td:nth-child(1)', text: 'Stanford University Libraries - Special Collections'
    end

    within '#collection' do
      expect(page).to have_css 'h4', text: 'Collection'
      expect(page).to have_css 'td:nth-child(1)', text: 'Annual report of the State Corporation Commission showing ' \
                                                        'the condition of the incorporated state banks and other institutions ' \
                                                        'operating in Virginia at the close of business'
    end

    within '#discovery' do
      expect(page).to have_css 'h4', text: 'Discovery'
      expect(page).to have_css 'td:nth-child(1)', text: 'Published to PURL'
      expect(page).to have_css 'td:nth-child(1)', text: 'SEARCHWORKS'
      expect(page).to have_css 'h5', text: 'Catkeys'
      expect(page).to have_css 'td:nth-child(1)', text: 'has value'
    end

    within '#rights' do
      expect(page).to have_css 'h4', text: 'Rights'
      expect(page).to have_css 'td:nth-child(1)', text: 'dark'
    end

    within '#contents' do
      expect(page).to have_css 'h4', text: 'Contents'
      expect(page).to have_css 'td:nth-child(1)', text: 'image'
      expect(page).to have_css 'td:nth-child(1)', text: 'Preserved file size'
    end

    within '#rights-information' do
      expect(page).to have_css 'h4', text: 'Rights information'
      expect(page).to have_css 'h5', text: 'Use & Reproduction'
      expect(page).to have_css 'h5', text: 'Copyright'
      expect(page).to have_css 'h5', text: 'License'
      expect(page).to have_css 'td:nth-child(1)', text: /govinfolib@lists.stanford.edu/
      expect(page).to have_css 'td:nth-child(1)', text: 'Copyright © Stanford University. All Rights Reserved.'
    end

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
      expect(page).to have_css 'td:nth-child(1)', text: 'has value'
      expect(page).to have_css 'td:nth-child(1)', text: 'English'
      expect(page).to have_css 'td:nth-child(1)', text: 'Cephalopoda'
      expect(page).to have_css 'td:nth-child(1)', text: 'Bermuda Islands'
    end

    within '#number-of-items' do
      expect(page).to have_css 'h4', text: 'Number of items'
      expect(page).to have_css 'td:nth-child(1)', text: 'item'
      expect(page).to have_css 'td.indented:nth-child(1)', text: 'Unknown Status'
    end
  end
end
