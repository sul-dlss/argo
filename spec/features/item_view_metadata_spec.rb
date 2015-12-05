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
    allow_any_instance_of(ApplicationController).to receive(:current_user)
      .and_return(@current_user)
  end

  scenario 'MD Source is "DOR"' do
    visit catalog_path 'druid:hj185vb7593'
    within '#document-identification-section' do
      expect(page).to have_css 'dt', text: 'DRUID:'
      expect(page).to have_css 'dd', text: 'druid:hj185vb7593'
      expect(page).to have_css 'dt', text: 'Object Type:'
      expect(page).to have_css 'dd', text: 'item'
      expect(page).to have_css 'dt', text: 'Content Type:'
      expect(page).to have_css 'dd', text: 'image'
      expect(page).to have_css 'dt.blacklight-metadata_source_ssi', text: 'MD Source'
      expect(page).to have_css 'dd.blacklight-metadata_source_ssi', text: 'DOR'
      expect(page).to have_css 'dt', text: 'Admin Policy:'
      expect(page).to have_css 'dd a', text: 'Stanford University Libraries - Special Collections'
      expect(page).to have_css 'dt', text: 'Project:'
      expect(page).to have_css 'dd a', text: 'Fuller Slides'
      expect(page).to have_css 'dt', text: 'Source:'
      expect(page).to have_css 'dd', text: 'fuller:M1090_S15_B02_F01_0126'
      expect(page).to have_css 'dt', text: 'Label:'
      expect(page).to have_css 'dd', text: 'M1090_S15_B02_F01_0126'
      expect(page).to have_css 'dt', text: 'IDs:'
      expect(page).to have_css 'dd', text: 'fuller:M1090_S15_B02_F01_0126, uuid:ad2d8894-7eba-11e1-b714-0016034322e7'
      expect(page).to have_css 'dt', text: 'Tags:'
      expect(page).to have_css 'dd a', text: 'Project : Fuller Slides'
      expect(page).to have_css 'dd a', text: 'Registered By : renzo'
      expect(page).to have_css 'dt', text: 'Status:'
      expect(page).to have_css 'dd', text: 'v1 Unknown Status'
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
