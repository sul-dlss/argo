# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Item view', js: true do
  before do
    sign_in create(:user), groups: ['sdr:administrator-role']
    allow(Dor::Workflow::Client).to receive(:new).and_return(workflow_client)
    allow(Preservation::Client.objects).to receive(:current_version).and_return('1')
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
  end

  let(:event) { Dor::Services::Client::Events::Event.new(event_type: 'shelve_request_received', data: { 'host' => 'dor-services-stage.stanford.edu' }) }
  let(:events_client) { instance_double(Dor::Services::Client::Events, list: [event]) }
  let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, current: 1) }
  let(:workflow_client) { instance_double(Dor::Workflow::Client, active_lifecycle: [], lifecycle: [], milestones: {}) }

  context 'when there is an error retrieving the cocina_model' do
    let(:files) do
      instance_double(Dor::Services::Client::Files, list: ['this_is_not_the_file_you_are_looking_for.txt'])
    end
    let(:object_client) { instance_double(Dor::Services::Client::Object, files: files, version: version_client, events: events_client) }

    before do
      allow(object_client).to receive(:find).and_raise(Dor::Services::Client::UnexpectedResponse)
    end

    it 'shows the page' do
      visit solr_document_path 'druid:hj185vb7593'
      within '.dl-horizontal' do
        expect(page).to have_css 'dt', text: 'DRUID:'
        expect(page).to have_css 'dd', text: 'druid:hj185vb7593'
      end
    end
  end

  context 'when the cocina_model exists' do
    let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model, files: files, version: version_client, events: events_client) }
    let(:cocina_model) { instance_double(Cocina::Models::DRO, administrative: dro_admin, structural: dro_struct, as_json: {}) }
    let(:dro_struct) { instance_double(Cocina::Models::DROStructural, contains: [fileset]) }
    let(:fileset) { instance_double(Cocina::Models::FileSet, structural: fs_structural) }
    let(:fs_structural) { instance_double(Cocina::Models::FileSetStructural, contains: [file]) }
    let(:file) { instance_double(Cocina::Models::File, administrative: file_admin, externalIdentifier: 'druid:hj185vb7593/M1090_S15_B02_F01_0126.jp2') }
    let(:file_admin) { instance_double(Cocina::Models::FileAdministrative, shelve: true, sdrPreserve: true) }
    let(:dro_admin) { instance_double(Cocina::Models::Administrative, releaseTags: []) }

    context 'when the file is not on the workspace' do
      let(:files) do
        instance_double(Dor::Services::Client::Files, list: ['this_is_not_the_file_you_are_looking_for.txt'])
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

        click_link 'descMetadata' # Open the datastream modal
        within '.code' do
          expect(page).to have_content '<mods:title type="main">Slides, IA 11, Geodesic Domes, Double Skin "Growth" House, N.C. State, 1953</mods:title>'
        end
        click_button '×' # close the modal

        within '.resource-list' do
          click_link 'M1090_S15_B02_F01_0126.jp2'
        end

        expect(page).to have_content 'Workspace: not available'
        expect(page).to have_link 'https://stacks.example.com/file/druid:hj185vb7593/M1090_S15_B02_F01_0126.jp2'
      end
    end

    context 'when the file is on the workspace' do
      let(:filename) { 'M1090_S15_B02_F01_0126.jp2' }
      let(:files) do
        instance_double(Dor::Services::Client::Files, list: [filename], retrieve: 'the file contents')
      end

      before do
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
end
