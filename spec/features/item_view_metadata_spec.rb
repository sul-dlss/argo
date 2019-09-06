# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Item view', js: true do
  before do
    sign_in create(:user), groups: ['sdr:administrator-role']
  end

  context 'when the file is not on the workspace' do
    before do
      allow_any_instance_of(Dor::Services::Client::Files).to receive(:list).and_return(['this_is_not_the_file_you_are_looking_for.txt'])
    end

    it 'shows the file info' do
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

      within '.resource-list' do
        click_link 'M1090_S15_B02_F01_0126.jp2'
      end

      expect(page).to have_content 'Workspace: not available'
      expect(page).to have_link 'https://stacks.example.com/file/druid:hj185vb7593/M1090_S15_B02_F01_0126.jp2'
    end
  end

  context 'when the file is on the workspace' do
    let(:filename) { 'M1090_S15_B02_F01_0126.jp2' }

    before do
      allow_any_instance_of(Dor::Services::Client::Files).to receive(:list).and_return([filename])
      allow_any_instance_of(Dor::Services::Client::Files).to receive(:retrieve).and_return('the file contents')

      page.driver.browser.download_path = '.'
    end

    after do
      File.delete(filename) if File.exist?(filename)
    end

    it 'can be downloaded' do
      visit solr_document_path 'druid:hj185vb7593'

      within '.resource-list' do
        click_link 'M1090_S15_B02_F01_0126.jp2'
      end

      within '.modal-content' do
        expect(page).to have_link 'https://stacks.example.com/file/druid:hj185vb7593/M1090_S15_B02_F01_0126.jp2'
      end
    end
  end
end
