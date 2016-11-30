require 'spec_helper'

describe 'Release history', js: true do
  let(:current_user) { mock_user(is_admin?: true) }
  before do
    expect_any_instance_of(CatalogController).to receive(:current_user)
      .at_least(1).times.and_return(current_user)
  end
  it 'items show a release history' do
    visit solr_document_path 'druid:qq613vj0238'
    expect(page).to have_css 'dt', text: 'Releases'
    expect(page).to have_css 'table.table thead tr th', text: 'Release'
    expect(page).to have_css 'tr td', text: /SEARCHWORKS/
    expect(page).to have_css 'tr td', text: /pjreed/
  end
  it 'adminPolicy objects do not show release history' do
    visit solr_document_path 'druid:fg464dn8891'
    expect(page).to_not have_css 'dt', text: 'Releases'
  end
end
