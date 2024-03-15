# frozen_string_literal: true

require 'rails_helper'

# Integration tests for expected behaviors of our Solr indexing choices, through
#   our whole stack: tests create cocina objects with factories, write them
#   to dor-services-app, index the new objects via dor-indexing-app and then use
#   the Argo UI to test Solr behavior such as search results and facet values.
#
# tag tests need javascript for facet testing because they are so slow to load in production
#   javascript possibly also needed for the edit tags modal
#
# rubocop:disable Capybara/ClickLinkOrButtonStyle
RSpec.describe 'Indexing and search results for tags', :js do
  let(:item) { FactoryBot.create_for_repository(:persisted_item) }
  let(:solr_id) { item.externalIdentifier }
  let(:project_tag) { 'Project : ARS 78s : broken' }
  let(:non_project_tag) { 'willet : murder of crows : curlew' }
  let(:project_tag2) { 'Project : jira-517' }
  let(:blacklight_config) { CatalogController.blacklight_config }
  let(:solr_conn) { blacklight_config.repository_class.new(blacklight_config).connection }

  # I wanted to do this as a before(:context) but after much teeth gnashing, I gave up
  #   That would have facilitated a single setup done once that each test could utilize.
  before do
    sign_in create(:user), groups: ['sdr:administrator-role']
    solr_conn.commit # ensure no deletes are pending
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
    item.description # ensure item is created before searching
  end

  after do
    solr_conn.delete_by_id(solr_id)
    solr_conn.commit
  end

  # one giant it block to reduce the time to run the tests; this is because I
  #   fussed with before(:context) for some hours and then gave up on it.
  it 'searches and facets behave as expected' do
    # ------- search behavior --------

    # project tags values include "Project" in searchable value
    fill_in 'q', with: 'Project'
    click_button 'search'
    expect(page).to have_content('1 entry found')
    expect(page).to have_css('dd.blacklight-id', text: solr_id)

    # project tags are searchable, tokenized
    ['ARS', '78s', 'ARS 78s', 'broken', '"78s broken"'].each do |token|
      fill_in 'q', with: token
      click_button 'search'
      expect(page).to have_content('1 entry found')
      expect(page).to have_css('dd.blacklight-id', text: solr_id)
    end

    # non-project tags tags are searchable, tokenized
    ['willet', 'murder of crows', 'murder', 'of', 'crows', 'curlew', '"crows curlew"'].each do |token|
      fill_in 'q', with: token
      click_button 'search'
      expect(page).to have_content('1 entry found')
      expect(page).to have_css('dd.blacklight-id', text: solr_id)
    end

    # Some Argo accessioneers have developed systems to work around problematic
    #   searching existing in Argo for years.  In some cases there are giant spreadsheets
    #   with links that depend on old things working.
    #
    # project tags with spaces around the colon work (searching)' do
    # Tag of “Project : jira-517” should match search term of “jira-517”
    # We do not need “jira” or “517” to match, but … it can?
    ['jira-517', 'jira', '517', '"jira 517"'].each do |token|
      fill_in 'q', with: token
      click_button 'search'
      expect(page).to have_content('1 entry found')
      expect(page).to have_css('dd.blacklight-id', text: solr_id)
    end

    # ------- facet behavior --------

    # project tags are a hierarchical facet
    fill_in 'q', with: solr_id
    click_button 'search'
    click_link_or_button 'Project'
    # ensure facet has been expanded by javascript
    expect(page).to have_css('#facet-exploded_project_tag_ssim')
    # Note that "Project" is not indexed as part of facet
    click_link_or_button 'ARS 78s'
    click_link_or_button 'broken'
    expect(page).to have_content('1 entry found')
    expect(page).to have_css('dd.blacklight-id', text: solr_id)

    # non-project tags are a hierarchical facet
    fill_in 'q', with: solr_id
    click_button 'search'
    click_link_or_button 'Tag'
    # ensure facet has been expanded by javascript
    expect(page).to have_css('#facet-exploded_nonproject_tag_ssim')
    click_link_or_button 'willet'
    skip 'FIXME: is this failing on spaces in nonproject tag values?'
    click_link_or_button 'murder of crows'
    click_link_or_button 'curlew'
    expect(page).to have_content('1 entry found')
    expect(page).to have_css('dd.blacklight-id', text: solr_id)
  end
end
# rubocop:enable Capybara/ClickLinkOrButtonStyle
