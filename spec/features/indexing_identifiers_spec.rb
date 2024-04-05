# frozen_string_literal: true

require 'rails_helper'

# Integration tests for expected behaviors of our Solr indexing choices, through
#   our whole stack: tests create cocina objects with factories, write them
#   to dor-services-app, index the new objects via dor-indexing-app and then use
#   the Argo UI to test Solr behavior such as search results and facet values.
RSpec.describe 'Indexing and search results for identifiers', skip: ENV['CI'].present? do
  let(:item) { FactoryBot.create_for_repository(:persisted_item) }
  let(:blacklight_config) { CatalogController.blacklight_config }
  let(:solr_conn) { blacklight_config.repository_class.new(blacklight_config).connection }
  let(:solr_id) { item.externalIdentifier }

  before do
    sign_in create(:user), groups: ['sdr:administrator-role']
    solr_conn.commit # ensure no deletes are pending
    visit '/'
    item.identification # ensure item is created before searching
  end

  after do
    solr_conn.delete_by_id(solr_id)
    solr_conn.commit
  end

  context 'for druids' do
    let(:prefixed_druid) { item.externalIdentifier }

    it 'matches query with bare and prefixed druid' do
      [prefixed_druid, prefixed_druid.split(':').last].each do |query|
        fill_in 'q', with: query
        click_button 'search'
        expect(page).to have_content('1 entry found')
        expect(page).to have_css('dd.blacklight-id', text: solr_id)
      end
    end
  end

  context 'for sourceids' do
    # SPEC: Source ID: M2549_2022-259_stertzer, where M2549 is the collection number and 2022-259 is the accession number
    # sul:M0997_S1_B473_021_0001 (S is for series, B is for box, F is for folder ...)
    let(:source_id) { "sul:M2549_2022-259_stertzer_#{SecureRandom.alphanumeric(12)}" }
    let(:item) { FactoryBot.create_for_repository(:persisted_item, source_id:) }

    it 'matches whole string, including prefix before first colon' do
      fill_in 'q', with: source_id
      click_button 'search'
      # expect a single result, but Solr may not finish commit for previous test delete in time
      # expect(page).to have_content('1 entry found')
      expect(page).to have_css('dd.blacklight-id', text: solr_id)
    end

    it 'matches without prefix before the first colon' do
      fill_in 'q', with: source_id.split(':').last
      click_button 'search'
      # expect a single result, but Solr may not finish commit for previous test delete in time
      # expect(page).to have_content('1 entry found')
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
        # expect a single result, but Solr may not finish commit for previous test delete in time
        # expect(page).to have_content('1 entry found')
        expect(page).to have_css('dd.blacklight-id', text: solr_id)
      end
    end

    it 'is not case sensitive' do
      fill_in 'q', with: 'm2549 STERTZER'
      click_button 'search'
      # expect a single result, but Solr may not finish commit for previous test delete in time
      # expect(page).to have_content('1 entry found')
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

    it 'matches query with bare and prefixed barcode' do
      [barcode, "barcode:#{barcode}"].each do |query|
        fill_in 'q', with: query
        click_button 'search'
        expect(page).to have_content('1 entry found')
        expect(page).to have_css('dd.blacklight-id', text: solr_id)
      end
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

    it 'matches catalog identifier with and without folio prefix' do
      [catalog_id, "folio:#{catalog_id}"].each do |query|
        fill_in 'q', with: query
        click_button 'search'
        expect(page).to have_content('1 entry found')
        expect(page).to have_css('dd.blacklight-id', text: solr_id)
      end
    end
  end

  context 'for DOIs' do
    # is there a reason to tokenize DOIs?

    it 'matches bare and "doi:" prefixed DOIs' do
      skip('write this test')
    end
  end
end
