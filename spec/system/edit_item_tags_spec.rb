# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Edit administrative tags for a single item', :js do
  let(:user) { create(:user) }
  let(:item) do
    FactoryBot.create_for_repository(:persisted_item)
  end

  let(:first_new_tag) { 'cow : pig' }
  let(:second_new_tag) { 'egret : raccoon : moose' }
  let(:replacement_tag) { 'bear : lynx' }

  before do
    sign_in user, groups: ['sdr:administrator-role']
    visit solr_document_path(item.externalIdentifier)
  end

  it 'adds and edits tags' do
    find("a[aria-label='Edit tags']").click
    within('#edit-modal') do
      click_button '+ Add another tag'
      fill_in currently_with: '', with: 'foo'
      click_button 'Save'
      expect(page).to have_content 'Tag must include the pattern:'

      fill_in currently_with: 'foo', with: first_new_tag
      click_button '+ Add another tag'
      fill_in currently_with: '', with: second_new_tag

      click_button 'Save'
    end
    expect(page).to have_content "Tags for #{item.externalIdentifier} have been updated!"
    within_table('Details') do
      expect(page).to have_content first_new_tag
      expect(page).to have_content second_new_tag
    end

    find("a[aria-label='Edit tags']").click
    within('#edit-modal') do
      find(:xpath, "//input[@value='#{first_new_tag}']").fill_in(with: replacement_tag)
      click_button 'Save'
    end
    expect(page).to have_content "Tags for #{item.externalIdentifier} have been updated!"
    within_table('Details') do
      expect(page).to have_content replacement_tag
      expect(page).to have_content second_new_tag
    end

    # Remove tags
    find("a[aria-label='Edit tags']").click
    within('#edit-modal') do
      find(:xpath, "//input[@value='#{replacement_tag}']/../..").first('button').click
      click_button 'Save'
    end
    expect(page).to have_content "Tags for #{item.externalIdentifier} have been updated!"
    within_table('Details') do
      expect(page).to have_no_content replacement_tag
      expect(page).to have_content second_new_tag
    end

    find("a[aria-label='Edit tags']").click
    within('#edit-modal') do
      find(:xpath, "//input[@value='#{second_new_tag}']/../..").first('button').click
      click_button 'Save'
    end
    expect(page).to have_content "Tags for #{item.externalIdentifier} have been updated!"
    within_table('Details') do
      expect(page).to have_no_content replacement_tag
      expect(page).to have_no_content second_new_tag
    end
  end
end
