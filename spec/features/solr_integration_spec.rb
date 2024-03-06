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
    visit '/'
  end

  after do
    solr_conn.delete_by_id(solr_id)
    solr_conn.commit
  end

  describe 'titles' do
    describe 'main title' do
      it 'exact match (anchored) on main title is first' do
        skip('write this test')
      end

      it 'unstemmed matches before stemmed matches' do
        skip('write this test')
      end

      it 'tokenized matches last' do
        skip('write this test')
      end

      it 'we do not use stopwords: all tokens are significant' do
        skip('write this test')
      end

      it 'searches work with and without diacritics' do
        skip('write this test')
      end

      it 'parallel values work' do
        # search on each parallel value - same results?
        skip('write this test')
      end
    end

    describe 'full title' do
      it 'exact match (anchored) on full title ...' do
        skip('write this test')
      end

      it 'untokenized match on (main/full) is before tokenized' do
        skip('write this test')
      end

      it 'we do not use stopwords: all tokens are significant' do
        skip('write this test')
      end

      it 'searches work with and without diacritics' do
        skip('write this test')
      end

      it 'parallel values work' do
        skip('write this test')
      end

      it 'structured values follow the order given' do
        # search on each parallel value - same results?
        skip('write this test')
      end
    end

    describe 'additional titles' do
      it 'exact match (anchored) on full title ...' do
        skip('write this test')
      end

      it 'untokenized match on (main/full) is before tokenized' do
        skip('write this test')
      end

      it 'we do not use stopwords: all tokens are significant' do
        skip('write this test')
      end

      it 'searches work with and without diacritics' do
        skip('write this test')
      end

      it 'parallel values work' do
        # search on each parallel value - same results?
        skip('write this test')
      end

      it 'structured values follow the order given' do
        skip('write this test')
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
                                           barcode: barcode
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
        expect(page).to have_css('#project-tag-facet > .blacklight-exploded_project_tag_ssim')
        # Note that "Project is not indexed as part of facet"
        click_link_or_button 'ARS 78s'
        click_link_or_button 'broken'
        expect(page).to have_content('1 entry found')
        expect(page).to have_css('dd.blacklight-id', text: solr_id)
      end

      it 'non-project tags are a hierarchical facet' do
        click_link_or_button 'Tag'
        # expect(page).to have_css('#nonproject-tag-facet > .blacklight-exploded_nonproject_tag_ssim')
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

    it 'case is honored in facets' do

    end

    it 'case is honored in display values' do

    end
  end

  describe 'stemming' do
    # Note:  don't check all the rules for the stemmer we use; just check that it is working
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
