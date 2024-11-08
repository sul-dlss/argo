# frozen_string_literal: true

require 'rails_helper'

# Integration tests for expected behaviors of our Solr indexing choices, through
#   our whole stack: tests create cocina objects with factories, write them
#   to dor-services-app, index the new objects via dor-indexing-app and then use
#   the Argo UI to test Solr behavior such as search results and facet values.
#
# rubocop:disable RSpec/RepeatedExample
RSpec.describe 'Indexing and search result behaviors', skip: 'tests need to be written' do
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
# rubocop:enable RSpec/RepeatedExample
