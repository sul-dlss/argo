# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Search behaviors' do
  let(:item) { FactoryBot.create_for_repository(:persisted_item) }
  let(:blacklight_config) { CatalogController.blacklight_config }
  let(:solr_conn) { blacklight_config.repository_class.new(blacklight_config).connection }

  before do
    sign_in create(:user), groups: ['sdr:administrator-role']
    visit '/'
  end

  after do
    solr_conn.delete_by_id(item.externalIdentifier)
    solr_conn.commit
  end

  # case folding happens for searching
  # stopwords are significant for searching
  # diacritics ignored for searching
  # only store one flavor of same data

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
        expect(page).to have_css('dd.blacklight-id', text: prefixed_druid)
      end

      it 'matches query with prefixed druid' do
        fill_in 'q', with: prefixed_druid
        click_button 'search'
        expect(page).to have_content('1 entry found')
        expect(page).to have_css('dd.blacklight-id', text: prefixed_druid)
      end
    end

    context 'for sourceids' do
      # SPEC: Source ID: M2549_2022-259_stertzer, where M2549 is the collection number and 2022-259 is the accession number
      # sul:M0997_S1_B473_021_0001 (S is for series, B is for box, F is for folder ...)
      let(:source_id) { "sul:M2549_2022-259_stertzer_#{SecureRandom.alphanumeric(12)}" }
      let(:item) { FactoryBot.create_for_repository(:persisted_item, source_id:) }
      let(:druid) { item.externalIdentifier }

      before do
        item.identification.sourceId # ensure item is created before searching
      end

      it 'matches whole string, including prefix before first colon' do
        fill_in 'q', with: source_id
        click_button 'search'
        expect(page).to have_content('1 entry found')
        expect(page).to have_css('dd.blacklight-id', text: druid)
      end

      it 'matches without prefix before the first colon' do
        fill_in 'q', with: source_id.split(':').last
        click_button 'search'
        expect(page).to have_content('1 entry found')
        expect(page).to have_css('dd.blacklight-id', text: druid)
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
          expect(page).to have_css('dd.blacklight-id', text: druid)
        end
      end

      it 'is not case sensitive' do
        fill_in 'q', with: 'm2549 STERTZER'
        click_button 'search'
        expect(page).to have_content('1 entry found')
        expect(page).to have_css('dd.blacklight-id', text: druid)
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
            expect(page).to have_css('dd.blacklight-id', text: druid)
          end
        end
      end
    end

    context 'for barcodes' do
      let(:barcode) { '20503740296' }
      let(:item) do
        FactoryBot.create_for_repository(:persisted_item, identification: {
                                           'sourceId' => "sul:#{SecureRandom.uuid}",
                                           'barcode' => barcode
                                         })
      end
      let(:druid) { item.externalIdentifier }

      before do
        item.identification.barcode # ensure item is created before searching
      end

      it 'matches query with bare barcode' do
        fill_in 'q', with: barcode
        click_button 'search'
        expect(page).to have_content('1 entry found')
        expect(page).to have_css('dd.blacklight-id', text: druid)
      end

      it 'matches query with prefixed barcode' do
        fill_in 'q', with: "barcode:#{barcode}"
        click_button 'search'
        expect(page).to have_content('1 entry found')
        expect(page).to have_css('dd.blacklight-id', text: druid)
      end
    end

    context 'for ILS (folio) identifiers' do
      it 'folio identifiers match with a, in, ... prefixes' do
        skip('write this test')
      end

      it 'folio identifiers match without their a/in/xx prefixes' do
        skip('write this test')
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

  describe 'tags' do
    it 'project tags are a separate facet from non-project tags' do
      skip('write this test')
    end

    it 'tag facets are be hierarchical (split on :)' do
      skip('write this test')
    end

    it '(both types of?) tags are searchable, tokenized' do
      skip('write this test')
    end

    it 'project tags with spaces around the colon work (searching)' do
      # Tag of “Project : jira-517” should match search term of “jira-517”
      # We do not need “jira” or “517” to match, but … it can?
      skip('write this test')
    end
  end

  describe 'collection title' do
    it 'does something' do
      skip('write this test')
    end
  end

  it 'date picker facet works' do
    skip('write this test')
  end

  it 'empty fields facet shows x and y' do
    skip('write this test')
  end

  describe 'we are happy with our stemming algorithm' do
    it 'does something' do
      skip('write this test')
    end
  end
end