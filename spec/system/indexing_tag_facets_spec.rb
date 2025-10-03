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
RSpec.describe 'Indexing and facet results for tags', :js, skip: ENV['CI'].present? do
  let(:item) { FactoryBot.create_for_repository(:persisted_item) }
  let(:solr_id) { item.externalIdentifier }
  let(:project_tag) { 'Project : ARS 78s : broken' }
  let(:non_project_tag) { 'willet : whimbrel : curlew' }
  let(:project_tag2) { 'Project : jira-517' }
  let(:blacklight_config) { CatalogController.blacklight_config }
  let(:solr_conn) { blacklight_config.repository_class.new(blacklight_config).connection }

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
    expect(page).to have_text('Successfully updated index') # rubocop:disable RSpec/ExpectInHook
    visit '/'
    fill_in 'q', with: solr_id
    click_button 'search'
  end

  after do
    solr_conn.delete_by_id(solr_id)
    solr_conn.commit
  end

  it 'project tags are hierarchical' do
    click_link_or_button('Project', wait: 20) # ensure facet has been expanded by javascript
    expect(page).to have_css('#facet-exploded_project_tag_ssimdv', wait: 20)
    # Note that "Project" is not indexed as part of facet
    click_link_or_button 'ARS 78s'
    click_link_or_button 'broken'
    expect(page).to have_content('1 entry found')
    expect(page).to have_css('dd.blacklight-id', text: solr_id)
  end

  it 'non-project tags are hierarchical', skip: 'unable to get non-project tag test working' do
    fill_in 'q', with: solr_id
    click_button 'search'
    click_link_or_button('Tag', wait: 20) # ensure facet has been expanded by javascript
    click_link_or_button 'willet'
    skip 'FIXME: failure perhaps associated with the toggle for the willet link being closed and unopenable'
    within('#facet-exploded_nonproject_tag_ssimdv') do
      click_link_or_button 'whimbrel'
      click_link_or_button 'curlew'
    end
    expect(page).to have_content('1 entry found')
    expect(page).to have_css('dd.blacklight-id', text: solr_id)
  end
end
# rubocop:enable Capybara/ClickLinkOrButtonStyle
