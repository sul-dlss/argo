# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Edit administrative tags for a single item', js: true do
  let(:user) { create(:user) }
  let(:item) do
    FactoryBot.create_for_repository(:item)
  end

  before do
    sign_in user, groups: ['sdr:administrator-role']
    visit solr_document_path(item.externalIdentifier)
  end

  it do
    # Add tags
    first_new_tag = 'cow : pig'
    second_new_tag = 'egret : raccoon : moose'
    click_link 'Edit tags'
    within('#blacklight-modal') do
      click_button '+ Add another tag'
      fill_in currently_with: '', with: first_new_tag
      click_button '+ Add another tag'
      fill_in currently_with: '', with: second_new_tag

      click_button 'Save'
    end
    expect(page).to have_content "Tags for #{item.externalIdentifier} have been updated!"
    within('dd.blacklight-tag_ssim') do
      expect(page).to have_content first_new_tag
      expect(page).to have_content second_new_tag
    end

    # Edit tags
    replacement_tag = 'bear : lynx'
    click_link 'Edit tags'
    within('#blacklight-modal') do
      find(:xpath, "//input[@value='#{first_new_tag}']").fill_in(with: replacement_tag)
      click_button 'Save'
    end
    expect(page).to have_content "Tags for #{item.externalIdentifier} have been updated!"
    within('dd.blacklight-tag_ssim') do
      expect(page).to have_content replacement_tag
      expect(page).to have_content second_new_tag
    end

    # Remove tags
    click_link 'Edit tags'
    within('#blacklight-modal') do
      find(:xpath, "//input[@value='#{replacement_tag}']/../..").first('button').click
      click_button 'Save'
    end
    expect(page).to have_content "Tags for #{item.externalIdentifier} have been updated!"
    within('dd.blacklight-tag_ssim') do
      expect(page).not_to have_content replacement_tag
      expect(page).to have_content second_new_tag
    end

    click_link 'Edit tags'
    within('#blacklight-modal') do
      find(:xpath, "//input[@value='#{second_new_tag}']/../..").first('button').click
      click_button 'Save'
    end
    expect(page).to have_content "Tags for #{item.externalIdentifier} have been updated!"
    within('dd.blacklight-tag_ssim') do
      expect(page).not_to have_content replacement_tag
      expect(page).not_to have_content second_new_tag
    end
  end
end
