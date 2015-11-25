require 'spec_helper'

feature 'Item view metadata' do
  before do
    @current_user = double(
      :webauth_user,
      login: 'sunetid',
      logged_in?: true,
      permitted_apos: [],
      is_admin: true,
      roles: []
    )
    allow_any_instance_of(ApplicationController).to receive(:current_user).
      and_return(@current_user)
  end

  scenario 'MD Source is "DOR"' do
    visit catalog_path 'druid:hj185vb7593'
    within '#document-identification-section' do
      expect(page).to have_css 'dt.blacklight-metadata_source_ssi', text: 'MD Source'
      expect(page).to have_css 'dd.blacklight-metadata_source_ssi', text: 'DOR'
    end
  end

  scenario 'MD Source is "Symphony"' do
    visit catalog_path 'druid:kv840rx2720'
    within '#document-identification-section' do
      expect(page).to have_css 'dt.blacklight-metadata_source_ssi', text: 'MD Source'
      expect(page).to have_css 'dd.blacklight-metadata_source_ssi', text: 'Symphony'
    end
  end

end
