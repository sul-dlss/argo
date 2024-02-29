# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Search behaviors' do
  let(:item) { FactoryBot.create_for_repository(:persisted_item) }

  before do
    sign_in create(:user), groups: ['sdr:administrator-role']
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

  describe 'source id searching' do
    # Manuscript number (Annie) - this would be present as a partial source ID or partial tag
    # Works in SearchWorks, not in Argo: M2549
    # Results in Argo (none), results in SW (multiple)
    # SPEC:  Source ID: M2549_2022-259_stertzer, where M2549 is the collection number and 2022-259 is the accession number

    it 'matches on a partial string (tokenized)' do
      skip('write this test')
    end

    it 'matches whole string' do
      skip('write this test')
    end

    it 'matches with or without "Source ID" prefix' do
      # source id searching with “:“ must still work
      skip('write this test')
    end

    it 'is not case sensitive' do
      skip('write this test')
    end

    it 'matches when there is a colon in the sourceid' do
      skip('write this test')
    end

    # worddelimiterfactory choices?
  end

  describe 'identifier searching' do
    context 'for druids' do
      let(:prefixed_druid) { item.externalIdentifier }

      it 'matches query with bare druid' do
        visit '/'
        fill_in 'q', with: prefixed_druid.split(':').last
        click_button 'search'
        expect(page).to have_content('1 entry found')
        expect(page).to have_css('dd.blacklight-id', text: prefixed_druid)
      end

      it 'matches query with prefixed druid' do
        visit '/'
        fill_in 'q', with: prefixed_druid
        click_button 'search'
        expect(page).to have_content('1 entry found')
        expect(page).to have_css('dd.blacklight-id', text: prefixed_druid)
      end
    end
    # ditto barcodes
    # folio instance hrids
    # doi
    # is there are reason to tokenize any of the above?

    context 'for sourceids' do

    end
    # source ids sold separately
    it 'folio identifiers match with a, in, ... prefixes' do
      skip('write this test')
    end

    it 'folio identifiers match without their a/in/xx prefixes' do
      skip('write this test')
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