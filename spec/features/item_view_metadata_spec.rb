require 'spec_helper'

feature 'Item view metadata' do
  let(:current_user) do
    mock_user(is_admin?: true)
  end
  before do
    expect_any_instance_of(CatalogController).to receive(:current_user)
      .at_least(1).times.and_return(current_user)
  end

  scenario 'MD Source is "DOR"' do
    visit solr_document_path 'druid:hj185vb7593'
    within '.dl-horizontal' do
      expect(page).to have_css 'dt', text: 'DRUID:'
      expect(page).to have_css 'dd', text: 'druid:hj185vb7593'
      expect(page).to have_css 'dt', text: 'Object Type:'
      expect(page).to have_css 'dd', text: 'item'
      expect(page).to have_css 'dt', text: 'Content Type:'
      expect(page).to have_css 'dd', text: 'image'
      expect(page).to have_css 'dt', text: 'Admin Policy:'
      expect(page).to have_css 'dd a', text: 'Stanford University Libraries - Special Collections'
      expect(page).to have_css 'dt', text: 'Project:'
      expect(page).to have_css 'dd a', text: 'Fuller Slides'
      expect(page).to have_css 'dt', text: 'Source:'
      expect(page).to have_css 'dd', text: 'fuller:M1090_S15_B02_F01_0126'
      expect(page).to have_css 'dt', text: 'IDs:'
      expect(page).to have_css 'dd', text: 'fuller:M1090_S15_B02_F01_0126, uuid:ad2d8894-7eba-11e1-b714-0016034322e7'
      expect(page).to have_css 'dt', text: 'Tags:'
      expect(page).to have_css 'dd a', text: 'Project : Fuller Slides'
      expect(page).to have_css 'dd a', text: 'Registered By : renzo'
      expect(page).to have_css 'dt', text: 'Status:'
      expect(page).to have_css 'dd', text: 'v1 Unknown Status'
    end
  end
end
