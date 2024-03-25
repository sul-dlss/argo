# frozen_string_literal: true

require 'rails_helper'

# Integration tests for expected behaviors of our Solr indexing choices, through
#   our whole stack: tests create cocina objects with factories, write them
#   to dor-services-app, index the new objects via dor-indexing-app and then use
#   the Argo UI to test Solr behavior such as search results and facet values.
RSpec.describe 'Indexing and search results for titles' do
  let(:item) { FactoryBot.create_for_repository(:persisted_item) }
  let(:blacklight_config) { CatalogController.blacklight_config }
  let(:solr_conn) { blacklight_config.repository_class.new(blacklight_config).connection }
  let(:solr_id) { item.externalIdentifier }

  before do
    sign_in create(:user), groups: ['sdr:administrator-role']
    solr_conn.commit # ensure no deletes are pending
    visit '/'
  end

  after do
    solr_conn.delete_by_id(solr_id)
    solr_conn.commit
  end

  describe 'simple value' do
    let(:item) { FactoryBot.create_for_repository(:persisted_item, title: title_value_simple) }
    let(:title_value_simple) { 'The Titlé' }

    before do
      item.description.title # ensure item is created before searching
    end

    it 'no stopwords, case and diacritics folded' do
      %w[The Titlé Title titlé title].each do |search_value|
        fill_in 'q', with: search_value
        click_button 'search'
        expect(page).to have_css('dd.blacklight-id', text: solr_id)
      end
    end

    it 'relevancy order is exact match (anchored) first, then exact match unanchored, then unstemmed, then stemmed' do
      plural_and_unanchored = FactoryBot.create_for_repository(:persisted_item, title: 'doing Titles for the fools') # extra and needs stemming
      unanchored = FactoryBot.create_for_repository(:persisted_item, title: "beyond #{title_value_simple} and more") # exact + extra
      plural = FactoryBot.create_for_repository(:persisted_item, title: 'the titles') # anchored but needs stemming
      fill_in 'q', with: title_value_simple
      click_button 'search'
      # check for item order as a measure of relevancy ranking
      expect(page).to have_content(/#{solr_id}.*#{unanchored.externalIdentifier}.*#{plural.externalIdentifier}.*#{plural_and_unanchored.externalIdentifier}/m)
      solr_conn.delete_by_id([plural_and_unanchored.externalIdentifier, plural.externalIdentifier, unanchored.externalIdentifier])
      # solr_conn.commit is in after block
    end
  end

  describe 'main title' do
    # main title is either indicated with status primary or is the first title (see cocina-models)
    #   thus the simple title value tests above apply to main title

    let(:chinese_value) { '标题' }
    let(:greek_value) { 'τίτλος' }
    let(:parallel_title_value) do
      {
        parallelValue: [
          {
            value: chinese_value
          },
          {
            value: greek_value
          }
        ]
      }
    end
    let(:item) { FactoryBot.create_for_repository(:persisted_item, title_values: [parallel_title_value]) }

    before do
      item.description.title # ensure item is created before searching
    end

    it 'parallel title matches searches of either value' do
      [chinese_value, greek_value].each do |search_value|
        fill_in 'q', with: search_value
        click_button 'search'
        expect(page).to have_css('dd.blacklight-id', text: solr_id)
      end
    end
  end

  describe 'full title' do
    # full title is different from main_title when there is a structuredValue with
    #   parts such as subtitle, part number, etc.; the main title only includes
    #   the 'main title' part (shockingly), but the full title includes all parts.
    # full title is either indicated with status primary or is the first title (see cocina-models)
    let(:main_title_value) { 'My Cat' }
    let(:subtitle_value) { 'A Book About Wingnut' }
    let(:structured_title_value) do
      {
        structuredValue: [
          {
            value: main_title_value,
            type: 'main title'
          },
          {
            value: subtitle_value,
            type: 'subtitle'
          }
        ]
      }
    end
    let(:item) { FactoryBot.create_for_repository(:persisted_item, title_values: [structured_title_value]) }

    before do
      item.description.title # ensure item is created before searching
    end

    it 'no stopwords, case and diacritics folded' do
      %w[A about aboüt About].each do |token|
        fill_in 'q', with: token
        click_button 'search'
        expect(page).to have_css('dd.blacklight-id', text: solr_id)
      end
    end

    it 'relevancy order is exact match (anchored) first, then unanchored, then unstemmed, then stemmed' do
      plural_and_unanchored_subtitle = "this is a #{subtitle_value}s and grommits"
      structured_title_value[:structuredValue][1][:value] = plural_and_unanchored_subtitle
      plural_and_unanchored = FactoryBot.create_for_repository(:persisted_item, title_values: [structured_title_value]) # extra and needs stemming
      plural_subtitle = "#{subtitle_value}s" # exact but needs stemming (or view as only first anchor match)
      structured_title_value[:structuredValue][1][:value] = plural_subtitle
      plural = FactoryBot.create_for_repository(:persisted_item, title_values: [structured_title_value]) # extra and needs stemming
      unanchored_subtitle = "before #{subtitle_value} is completed" # exact + extra
      structured_title_value[:structuredValue][1][:value] = unanchored_subtitle
      unanchored = FactoryBot.create_for_repository(:persisted_item, title_values: [structured_title_value]) # extra and needs stemming
      fill_in 'q', with: subtitle_value
      click_button 'search'
      # check for item order as a measure of relevancy ranking
      expect(page).to have_content(/#{solr_id}.*#{unanchored.externalIdentifier}.*#{plural.externalIdentifier}.*#{plural_and_unanchored.externalIdentifier}/m)
      solr_conn.delete_by_id([plural_and_unanchored.externalIdentifier, plural.externalIdentifier, unanchored.externalIdentifier])
      # solr_conn.commit is in after block
    end

    it 'parallel title matches searches of either value' do
      subtitle = 'all about Vinsky'
      chinese_subtitle = '关于Vinsky'
      parallel_title_value = {
        parallelValue: [
          {
            structuredValue: [
              {
                value: 'main',
                type: 'main title'
              },
              {
                value: subtitle,
                type: 'subtitle'
              }
            ]
          },
          {
            structuredValue: [
              {
                value: '主',
                type: 'main title'
              },
              {
                value: chinese_subtitle,
                type: 'subtitle'
              }
            ]
          }
        ]
      }
      my_item = FactoryBot.create_for_repository(:persisted_item, title_values: [parallel_title_value])
      solr_id = my_item.externalIdentifier
      [subtitle, chinese_subtitle].each do |search_value|
        fill_in 'q', with: search_value
        click_button 'search'
        expect(page).to have_css('dd.blacklight-id', text: solr_id)
      end
    end
  end

  describe 'additional titles' do
    # additional titles are title values other than the main/full values (see cocina-models)
    let(:primary_title) do
      {
        value: 'primary title',
        status: 'primary'
      }
    end
    let(:additional_title_value) { 'vegetables and fruits' }
    let(:additional_title) { { value: additional_title_value } }
    let(:title_values) { [primary_title, additional_title] }
    let(:item) { FactoryBot.create_for_repository(:persisted_item, title_values:) }

    before do
      item.description.title # ensure item is created before searching
    end

    it 'no stopwords, case and diacritics folded' do
      %w[and Vegetåbles vegeTABLEs].each do |token|
        fill_in 'q', with: token
        click_button 'search'
        expect(page).to have_css('dd.blacklight-id', text: solr_id)
      end
    end

    it 'relevancy order is exact match (anchored) first, then unstemmed, then stemmed (phrase), then unordered tokens' do
      same_stems_value = 'vegetable and fruit'
      same_stems = FactoryBot.create_for_repository(:persisted_item, title_values: [primary_title, { value: same_stems_value }])
      order_reversed_value = 'fruits and vegetables'
      order_reversed = FactoryBot.create_for_repository(:persisted_item, title_values: [primary_title, { value: order_reversed_value }])
      unanchored_value = "before #{additional_title_value} and more"
      unanchored = FactoryBot.create_for_repository(:persisted_item, title_values: [primary_title, { value: unanchored_value }])
      same_stems.externalIdentifier
      order_reversed.externalIdentifier
      unanchored.externalIdentifier # ensure items are created before searching
      fill_in 'q', with: additional_title_value
      click_button 'search'
      # check for item order as a measure of relevancy ranking
      expect(page).to have_content(/#{solr_id}.*#{unanchored.externalIdentifier}.*#{same_stems.externalIdentifier}.*#{order_reversed.externalIdentifier}/m)
      solr_conn.delete_by_id([same_stems.externalIdentifier, order_reversed.externalIdentifier, unanchored.externalIdentifier])
      # solr_conn.commit is in after block
    end

    it 'parallel title matches searches of either value' do
      subtitle = 'all about Vinsky'
      chinese_subtitle = '关于Vinsky'
      parallel_title_value = {
        parallelValue: [
          {
            structuredValue: [
              {
                value: 'main',
                type: 'main title'
              },
              {
                value: subtitle,
                type: 'subtitle'
              }
            ]
          },
          {
            structuredValue: [
              {
                value: '主',
                type: 'main title'
              },
              {
                value: chinese_subtitle,
                type: 'subtitle'
              }
            ]
          }
        ]
      }
      title_values = [
        primary_title,
        parallel_title_value
      ]
      my_item = FactoryBot.create_for_repository(:persisted_item, title_values:)
      solr_id = my_item.externalIdentifier
      fill_in 'q', with: subtitle
      click_button 'search'
      expect(page).to have_css('dd.blacklight-id', text: solr_id)
      fill_in 'q', with: chinese_subtitle
      click_button 'search'
      expect(page).to have_css('dd.blacklight-id', text: solr_id)
    end
  end

  describe 'relevancy ranking among title types' do
    let(:search_term) { 'matching' }
    let(:main_title_match) { FactoryBot.create_for_repository(:persisted_item, title: "main title #{search_term}") }
    let(:full_title_matching_value) do
      {
        structuredValue: [
          {
            value: 'main title',
            type: 'main title'
          },
          {
            value: "subtitle #{search_term}",
            type: 'subtitle'
          }
        ]
      }
    end
    let(:full_title_match) { FactoryBot.create_for_repository(:persisted_item, title_values: [full_title_matching_value]) }
    let(:primary_title) do
      {
        value: 'primary title for additional title in results',
        status: 'primary'
      }
    end
    let(:additional_title_value) { search_term }
    let(:additional_title) { { value: additional_title_value } }
    let(:title_values) { [primary_title, additional_title] }
    let(:additional_title_match) { FactoryBot.create_for_repository(:persisted_item, title_values:) }
    let(:unmatching) { FactoryBot.create_for_repository(:persisted_item, title: 'not there') }

    before do
      # ensure items are created before searching
      additional_title_match.description
      full_title_match.description
      main_title_match.description
      unmatching.description
    end

    it 'relevancy order has matches in main title before matches in full title before matches in additional title' do
      fill_in 'q', with: search_term
      click_button 'search'
      # check for item order as a measure of relevancy ranking
      expect(page).to have_content('3 of 3') # unmatching isn't there, as expected
      expect(page).to have_content(/#{main_title_match.externalIdentifier}.*#{full_title_match.externalIdentifier}.*#{additional_title_match.externalIdentifier}/m)
      solr_conn.delete_by_id([main_title_match.externalIdentifier, full_title_match.externalIdentifier, additional_title_match.externalIdentifier])
    end
  end
end
