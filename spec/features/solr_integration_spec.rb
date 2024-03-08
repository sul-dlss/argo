# frozen_string_literal: true

require 'rails_helper'

# Integration tests for expected behaviors of our Solr indexing choices, through
#   our whole stack: tests create cocina objects with factories, write them
#   to dor-services-app, index the new objects via dor-indexing-app and then use
#   the Argo UI to test Solr behavior such as search results and facet values.
# rubocop:disable Capybara/ClickLinkOrButtonStyle
RSpec.describe 'Search behaviors' do
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

  describe 'titles' do
    before do
      item.description # ensure item is created before searching
    end

    describe 'simple value' do
      let(:item) { FactoryBot.create_for_repository(:persisted_item, title: title_value_simple) }
      let(:title_value_simple) { 'The Titlé' }

      it 'there are no stopwords: all tokens are significant' do
        fill_in 'q', with: 'The'
        click_button 'search'
        expect(page).to have_css('dd.blacklight-id', text: solr_id)
      end

      it 'searches are not case sensitive and work with and without diacritics' do
        %w[Titlé Title titlé title].each do |token|
          fill_in 'q', with: token
          click_button 'search'
          expect(page).to have_css('dd.blacklight-id', text: solr_id)
        end
      end

      it 'relevancy order is exact match (anchored) first, then unstemmed, then stemmed' do
        plural_and_unanchored = FactoryBot.create_for_repository(:persisted_item, title: 'doing Titles for the fools') # extra and needs stemming
        unanchored = FactoryBot.create_for_repository(:persisted_item, title: "beyond #{title_value_simple} and more") # exact + extra
        plural = FactoryBot.create_for_repository(:persisted_item, title: 'the titles') # anchored but needs stemming
        fill_in 'q', with: title_value_simple
        click_button 'search'
        click_button 'Sort'
        click_link 'Relevance'
        # check for item order as a measure of relevancy ranking
        expect(page).to have_content(/#{solr_id}.*#{plural.externalIdentifier}.*#{unanchored.externalIdentifier}.*#{plural_and_unanchored.externalIdentifier}/m)
        solr_conn.delete_by_id([plural_and_unanchored.externalIdentifier, plural.externalIdentifier, unanchored.externalIdentifier])
        # solr_conn.commit is in after block
      end
    end

    describe 'main title' do
      # main title is either indicated with status primary or is the first title (see cocina-models)
      #   thus the simple title value tests above apply to main title

      it 'parallel title matches searches of either value' do
        chinese_value = '标题'
        greek_value = 'τίτλος'
        parallel_title_value = {
          parallelValue: [
            {
              value: chinese_value
            },
            {
              value: greek_value
            }
          ]
        }
        my_item = FactoryBot.create_for_repository(:persisted_item, title_values: [parallel_title_value])
        solr_id = my_item.externalIdentifier
        fill_in 'q', with: chinese_value
        click_button 'search'
        expect(page).to have_css('dd.blacklight-id', text: solr_id)
        fill_in 'q', with: greek_value
        click_button 'search'
        expect(page).to have_css('dd.blacklight-id', text: solr_id)
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

      it 'there are no stopwords: all tokens are significant' do
        fill_in 'q', with: 'A'
        click_button 'search'
        expect(page).to have_css('dd.blacklight-id', text: solr_id)
      end

      it 'searches are not case sensitive and work with and without diacritics' do
        %w[about aboüt About].each do |token|
          fill_in 'q', with: token
          click_button 'search'
          expect(page).to have_css('dd.blacklight-id', text: solr_id)
        end
      end

      it 'relevancy order is exact match (anchored) first, then unanchored, then unstemmed, then stemmed' do
        plural_and_unanchored_subtitle = "this is a #{subtitle_value} and grommits"
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
        click_button 'Sort'
        click_link 'Relevance'
        # check for item order as a measure of relevancy ranking
        expect(page).to have_content(/#{solr_id}.*#{plural.externalIdentifier}.*#{unanchored.externalIdentifier}.*#{plural_and_unanchored.externalIdentifier}/m)
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
        fill_in 'q', with: subtitle
        click_button 'search'
        expect(page).to have_css('dd.blacklight-id', text: solr_id)
        fill_in 'q', with: chinese_subtitle
        click_button 'search'
        expect(page).to have_css('dd.blacklight-id', text: solr_id)
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

      it 'there are no stopwords: all tokens are significant' do
        fill_in 'q', with: 'and'
        click_button 'search'
        expect(page).to have_css('dd.blacklight-id', text: solr_id)
      end

      it 'searches are not case sensitive and work with and without diacritics' do
        %w[Vegetåbles vegeTABLEs].each do |token|
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
        fill_in 'q', with: additional_title_value
        click_button 'search'
        click_button 'Sort'
        click_link 'Relevance'
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

    describe 'relevancy ranking between title types' do
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

      it 'relevancy order is matches in main title before matches in full title before matches in additional title' do
        fill_in 'q', with: search_term
        click_button 'search'
        click_button 'Sort'
        click_link 'Relevance'
        # check for item order as a measure of relevancy ranking
        expect(page).to have_content('3 of 3') # unmatching isn't there, as expected
        expect(page).to have_content(/#{main_title_match.externalIdentifier}.*#{full_title_match.externalIdentifier}.*#{additional_title_match.externalIdentifier}/m)
        solr_conn.delete_by_id([main_title_match.externalIdentifier, full_title_match.externalIdentifier, additional_title_match.externalIdentifier])
      end
    end
  end

  describe 'searching by author name' do
    it 'gets good results' do
      skip('write this test')
    end

    it 'results have primary author matches high enough' do
      skip('write this test')
    end

    it 'author names are not stemmed' do
      skip('write this test')
    end

    it 'works with and without diacritics' do
      skip('write this test')
    end

    it 'case does not matter for searching' do
      skip('write this test')
    end
  end

  describe 'catch all field for searching' do
    it 'searching for text in any reasonable place in the metadata matches' do
      # notes, blah blah -- stuff in descriptive_xxx fields that isn't indexed anywhere else
      skip('write this test')
    end

    it 'has exact matches before stemmed matches' do
      skip('write this test')
    end

    it 'is not case sensitive' do
      skip('write this test')
    end

    it 'does not remove stopwords' do
      skip('write this test')
    end

    it 'is not sensitive to diacritics' do
      skip('write this test')
    end
  end

  describe 'identifier searching' do
    context 'for druids' do
      let(:prefixed_druid) { item.externalIdentifier }

      it 'matches query with bare druid' do
        fill_in 'q', with: prefixed_druid.split(':').last
        click_button 'search'
        expect(page).to have_content('1 entry found')
        expect(page).to have_css('dd.blacklight-id', text: solr_id)
      end

      it 'matches query with prefixed druid' do
        fill_in 'q', with: prefixed_druid
        click_button 'search'
        expect(page).to have_content('1 entry found')
        expect(page).to have_css('dd.blacklight-id', text: solr_id)
      end
    end

    context 'for sourceids' do
      # SPEC: Source ID: M2549_2022-259_stertzer, where M2549 is the collection number and 2022-259 is the accession number
      # sul:M0997_S1_B473_021_0001 (S is for series, B is for box, F is for folder ...)
      let(:source_id) { "sul:M2549_2022-259_stertzer_#{SecureRandom.alphanumeric(12)}" }
      let(:item) { FactoryBot.create_for_repository(:persisted_item, source_id:) }

      before do
        item.identification.sourceId # ensure item is created before searching
      end

      it 'matches whole string, including prefix before first colon' do
        fill_in 'q', with: source_id
        click_button 'search'
        expect(page).to have_content('1 entry found')
        expect(page).to have_css('dd.blacklight-id', text: solr_id)
      end

      it 'matches without prefix before the first colon' do
        fill_in 'q', with: source_id.split(':').last
        click_button 'search'
        expect(page).to have_content('1 entry found')
        expect(page).to have_css('dd.blacklight-id', text: solr_id)
      end

      it 'matches source_id fragments' do
        fragments = [
          'M2549',
          '2022-259', # accession number
          'M2549_2022-259',
          'M2549 2022 259',
          'stertzer',
          '259_stertzer',
          '259-stertzer',
          '259 stertzer'
        ]
        fragments.each do |fragment|
          fill_in 'q', with: fragment
          click_button 'search'
          expect(page).to have_content('1 entry found')
          expect(page).to have_css('dd.blacklight-id', text: solr_id)
        end
      end

      it 'is not case sensitive' do
        fill_in 'q', with: 'm2549 STERTZER'
        click_button 'search'
        expect(page).to have_content('1 entry found')
        expect(page).to have_css('dd.blacklight-id', text: solr_id)
      end

      punctuation_source_ids = [
        'sulcons:8552-RB_Miscellanies_agabory,Before treatment photos',
        'Archiginnasio:Bassi_Box10_Folder2_Item3.14',
        'Revs:2012-015GHEW-CO-1980-b1_1.16_0007'
      ]
      punctuation_source_ids.each do |punctuation_source_id|
        context "when punctuation in #{punctuation_source_id}" do
          let(:source_id) { "#{punctuation_source_id}.#{SecureRandom.alphanumeric(4)}" }

          it 'matches without punctuation' do
            fill_in 'q', with: source_id.gsub(/[_\-:.,]/, ' ')
            click_button 'search'
            expect(page).to have_content('1 entry found')
            expect(page).to have_css('dd.blacklight-id', text: solr_id)
          end
        end
      end
    end

    context 'for barcodes' do
      let(:barcode) { '20503740296' }
      let(:item) do
        FactoryBot.create_for_repository(:persisted_item, identification: {
                                           sourceId: "sul:#{SecureRandom.uuid}",
                                           barcode:
                                         })
      end

      before do
        item.identification.barcode # ensure item is created before searching
      end

      it 'matches query with bare barcode' do
        fill_in 'q', with: barcode
        click_button 'search'
        expect(page).to have_content('1 entry found')
        expect(page).to have_css('dd.blacklight-id', text: solr_id)
      end

      it 'matches query with prefixed barcode' do
        fill_in 'q', with: "barcode:#{barcode}"
        click_button 'search'
        expect(page).to have_content('1 entry found')
        expect(page).to have_css('dd.blacklight-id', text: solr_id)
      end
    end

    context 'for ILS (folio) identifiers' do
      let(:catalog_id) { 'a11403803' }
      let(:item) do
        FactoryBot.create_for_repository(:persisted_item, identification: {
                                           sourceId: "sul:#{SecureRandom.uuid}",
                                           catalogLinks: [{
                                             catalog: 'folio',
                                             refresh: false,
                                             catalogRecordId: catalog_id
                                           }]
                                         })
      end

      before do
        item.identification.catalogLinks # ensure item is created before searching
      end

      it 'matches catalog identifier with folio prefix' do
        fill_in 'q', with: "folio:#{catalog_id}"
        click_button 'search'
        expect(page).to have_content('1 entry found')
        expect(page).to have_css('dd.blacklight-id', text: solr_id)
      end

      it 'matches catalog identifier without folio prefix' do
        fill_in 'q', with: catalog_id
        click_button 'search'
        expect(page).to have_content('1 entry found')
        expect(page).to have_css('dd.blacklight-id', text: solr_id)
      end
    end

    context 'for DOIs' do
      it 'matches bare DOI' do
        skip('write this test')
      end

      it 'matches DOI with "doi:" prefix' do
        skip('write this test')
      end

      # is there a reason to tokenize DOIs?
    end
  end

  # tag tests need javascript for facet testing because they are so slow to load in production
  #   javascript possibly also needed for the edit tags modal
  describe 'tags', :js do
    let(:project_tag) { 'Project : ARS 78s : broken' }
    let(:non_project_tag) { 'willet : murder of crows : curlew' }
    let(:project_tag2) { 'Project : jira-517' }

    before do
      visit solr_document_path(item.externalIdentifier)
      find("a[aria-label='Edit tags']").click
      within('#edit-modal') do
        click_button '+ Add another tag'
        fill_in currently_with: '', with: project_tag
        click_button '+ Add another tag'
        fill_in currently_with: '', with: non_project_tag
        click_button '+ Add another tag'
        fill_in currently_with: '', with: project_tag2
        click_button 'Save'
      end
      click_link_or_button 'Reindex'
      # wait for indexing
      expect(page).to have_text('Successfully updated index') # rubocop:disable RSpec/ExpectInHook
      visit '/'
    end

    describe 'as facets' do
      before do
        fill_in 'q', with: solr_id
        click_button 'search'
      end

      it 'project tags are a hierarchical facet' do
        click_link_or_button 'Project'
        # ensure facet has been expanded by javascript
        expect(page).to have_css('#project-tag-facet > .blacklight-exploded_project_tag_ssim')
        # Note that "Project" is not indexed as part of facet
        click_link_or_button 'ARS 78s'
        click_link_or_button 'broken'
        expect(page).to have_content('1 entry found')
        expect(page).to have_css('dd.blacklight-id', text: solr_id)
      end

      it 'non-project tags are a hierarchical facet' do
        click_link_or_button 'Tag'
        # ensure facet has been expanded by javascript
        expect(page).to have_css('#nonproject-tag-facet > .blacklight-exploded_nonproject_tag_ssim')
        click_link 'willet'
        skip 'FIXME: not sure why this one is failing'
        # click_button 'button.toggle-handle.collapsed'
        click_link 'murder of crows'
        click_link_or_button 'curlew'
        expect(page).to have_content('1 entry found')
        expect(page).to have_css('dd.blacklight-id', text: solr_id)
      end
    end

    # TODO: do we want this? ask Andrew
    it 'project tags values include "Project" in searchable value' do
      fill_in 'q', with: 'Project'
      click_button 'search'
      expect(page).to have_content('1 entry found')
      expect(page).to have_css('dd.blacklight-id', text: solr_id)
    end

    it 'project tags are searchable, tokenized' do
      ['ARS', '78s', 'ARS 78s', 'broken', '"78s broken"'].each do |token|
        fill_in 'q', with: token
        click_button 'search'
        expect(page).to have_content('1 entry found')
        expect(page).to have_css('dd.blacklight-id', text: solr_id)
      end
    end

    it 'non-project tags tags are searchable, tokenized' do
      ['willet', 'murder of crows', 'murder', 'of', 'crows', 'curlew', '"crows curlew"'].each do |token|
        fill_in 'q', with: token
        click_button 'search'
        expect(page).to have_content('1 entry found')
        expect(page).to have_css('dd.blacklight-id', text: solr_id)
      end
    end

    # Some Argo accessioneers have developed systems to work around problematic
    #   searching existing in Argo for years.  In some cases there are giant spreadsheets
    #   with links that depend on old things working.
    it 'project tags with spaces around the colon work (searching)' do
      # Tag of “Project : jira-517” should match search term of “jira-517”
      # We do not need “jira” or “517” to match, but … it can?
      ['jira-517', 'jira', '517', '"jira 517"'].each do |token|
        fill_in 'q', with: token
        click_button 'search'
        expect(page).to have_content('1 entry found')
        expect(page).to have_css('dd.blacklight-id', text: solr_id)
      end
    end
  end

  it 'items match searches that match their collection title' do
    skip('write this test')
  end

  it 'date picker facet works' do
    skip('write this test')
  end

  it 'empty fields facet shows x and y' do
    skip('write this test')
  end

  it 'we do not use stopwords - all words are significant for searching' do
    skip('write this test')
  end

  it 'diacritics are ignored for searching' do
    skip('write this test')
  end

  describe 'case folding' do
    it 'case does not affect search results' do
      skip('write this test, and include some non-latin scripts with case')
    end

    it 'case is significant in facets' do
      skip('write this test, and include some non-latin scripts with case')
    end
  end

  describe 'stemming' do
    # NOTE:  don't check all the rules for the stemmer we use; just check that it is working
    it 'searches with and without plurals match, but exact match is first (but only for title)' do
      skip('write this test')
      # sses -> ss
      # es -> e
      # ies -> y
      # s -> ""
    end

    it 'searches with and without stemming "ing" match' do
      skip('write this test')
    end

    it 'searches with and without stemming "ed" match' do
      skip('write this test')
    end

    it "searches with and without stemming 's or ending ' match" do
      skip('write this test')
    end

    it 'am, are, is stem to be' do
      skip('write this test')
    end
  end
end
# rubocop:enable Capybara/ClickLinkOrButtonStyle
