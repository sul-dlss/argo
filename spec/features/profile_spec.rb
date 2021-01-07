# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Profile' do
  before do
    ActiveFedora::SolrService.instance.conn.delete_by_query("#{SolrDocument::FIELD_OBJECT_TYPE}:item")

    ActiveFedora::SolrService.add(id: 'druid:xb482ww9999',
                                  objectType_ssim: 'item',
                                  topic_ssim: 'Cephalopoda',
                                  sw_subject_geographic_ssim: 'Bermuda Islands',
                                  tag_ssim: ['Project : Argo Demo', 'Registered By : mbklein'])

    ActiveFedora::SolrService.add(id: 'druid:xb482bw3988',
                                  objectType_ssim: 'item',
                                  content_type_ssim: 'image',
                                  SolrDocument::FIELD_RELEASED_TO => 'SEARCHWORKS',
                                  collection_title_ssim: 'Annual report of the State Corporation Commission',
                                  apo_title_ssim: 'Stanford University Libraries - Special Collections',
                                  rights_descriptions_ssim: 'dark',
                                  use_statement_ssim: 'contact govinfolib@lists.stanford.edu',
                                  copyright_ssim: 'Copyright © Stanford University. All Rights Reserved.',
                                  sw_format_ssim: 'Image',
                                  sw_language_ssim: 'English',
                                  processing_status_text_ssi: 'Unknown Status')
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
      expect(page).to have_css 'td:nth-child(1)', text: 'Annual report of the State Corporation Commission'
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
