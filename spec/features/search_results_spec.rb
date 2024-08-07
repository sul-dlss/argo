# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Search results' do
  before do
    sign_in create(:user), groups: ['sdr:administrator-role']
  end

  let(:blacklight_config) { CatalogController.blacklight_config }
  let(:solr_conn) { blacklight_config.repository_class.new(blacklight_config).connection }

  context 'for a book' do
    before do
      solr_conn.delete_by_query("#{SolrDocument::FIELD_OBJECT_TYPE}:item")

      solr_conn.add(:id => 'druid:hj185xx2222',
                    SolrDocument::FIELD_OBJECT_TYPE => 'item',
                    :content_type_ssim => 'book')
      solr_conn.commit
    end

    it 'contains Blacklight default index page tools' do
      visit search_catalog_path f: { content_type_ssim: ['book'] }
      within '.constraints-container' do
        expect(page).to have_css '.catalog_startOverLink', text: 'Start Over'
      end
      within '.search-widgets' do
        expect(page).to have_css 'a.btn.btn-outline-primary', text: 'Bulk Action'
        within '#sort-dropdown' do
          expect(page).to have_css 'button', text: 'Sort by Relevance'
          expect(page).to have_css '.dropdown-item', count: 2
        end
        within '#per_page-dropdown' do
          expect(page).to have_css 'button', text: '10 per page'
          expect(page).to have_css '.dropdown-item', count: 4
        end
        within '.report-toggle' do
          expect(page).to have_css 'a', text: 'Report View'
          expect(page).to have_css 'a', text: 'Workflow Grid View'
        end
      end
    end
  end

  describe 'an individual result' do
    before do
      solr_conn.delete_by_query("#{SolrDocument::FIELD_OBJECT_TYPE}:item")

      solr_conn.add(:id => 'druid:hj185xx2222',
                    SolrDocument::FIELD_OBJECT_TYPE => 'item',
                    :content_type_ssim => 'image',
                    :status_ssi => 'v1 Unknown Status',
                    SolrDocument::FIELD_APO_ID => 'info:fedora/druid:ww057qx5555',
                    SolrDocument::FIELD_APO_TITLE => 'Stanford University Libraries - Special Collections',
                    :project_tag_ssim => 'Fuller Slides',
                    :source_id_ssi => 'fuller:M1090_S15_B02_F01_0126',
                    :identifier_tesim => ['fuller:M1090_S15_B02_F01_0126',
                                          'uuid:ad2d8894-7eba-11e1-b714-0016034322e7'],
                    :tag_ssim => ['Project : Fuller Slides', 'Registered By : renzo'])
      solr_conn.commit
    end

    it 'contains appropriate metadata fields' do
      visit search_catalog_path f: { objectType_ssim: ['item'] }
      within('.document:nth-child(1)') do
        within '.document-metadata' do
          expect(page).to have_css 'dt', text: 'DRUID:'
          expect(page).to have_css 'dd', text: 'druid:hj185xx2222'
          expect(page).to have_css 'dt', text: 'Object Type:'
          expect(page).to have_css 'dd', text: 'item'
          expect(page).to have_css 'dt', text: 'Content Type:'
          expect(page).to have_css 'dd', text: 'image'
          expect(page).to have_css 'dt', text: 'Status:'
          expect(page).to have_css 'dd', text: 'v1 Unknown Status'
          expect(page).to have_css 'dt', text: 'Admin Policy:'
          expect(page).to have_css 'dd a', text: 'Stanford University Libraries - Special Collections'
          expect(page).to have_css 'dt', text: 'Project:'
          expect(page).to have_css 'dd a', text: 'Fuller Slides'
          expect(page).to have_css 'dt', text: 'IDs'
          expect(page).to have_css 'dd',
                                   text: 'fuller:M1090_S15_B02_F01_0126, uuid:ad2d8894-7eba-11e1-b714-0016034322e7'
          expect(page).to have_css 'dt', text: 'Source:'
          expect(page).to have_css 'dd', text: 'fuller:M1090_S15_B02_F01_0126'
        end
      end
    end
  end

  describe 'the thumbnail' do
    before do
      solr_conn.add(:id => 'druid:hj185xx2222',
                    SolrDocument::FIELD_OBJECT_TYPE => 'item',
                    :first_shelved_image_ss => 'M1090_S15_B02_F01_0126.jp2')
      solr_conn.commit
    end

    it 'contains document image thumbnail' do
      visit search_catalog_path f: { objectType_ssim: ['item'] }
      expect(page).to have_css '.document-thumbnail a img'
    end
  end
end
