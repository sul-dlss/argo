# frozen_string_literal: true

require 'rails_helper'

# Feature tests for the spreadsheet bulk uploads view.
RSpec.describe 'Bulk jobs view', :js do
  before do
    solr_conn.add(id: apo_id, objectType_ssim: 'adminPolicy',
                  'apo_role_dor-apo-manager_ssim': ['workgroup:sdr:map-staff'])
    solr_conn.commit
    sign_in create(:user), groups: ['sdr:map-staff']

    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    allow(Repository).to receive(:find).and_return(cocina_model)
  end

  let(:blacklight_config) { CatalogController.blacklight_config }
  let(:solr_conn) { blacklight_config.repository_class.new(blacklight_config).connection }
  let(:object_client) { instance_double(Dor::Services::Client::Object) }
  let(:cocina_model) { build(:admin_policy_with_metadata, id: apo_id) }
  let(:apo_id) { 'druid:hv992yv2222' }

  context 'when on the page with the list of bulk jobs' do
    let(:workflow_client) { instance_double(Dor::Workflow::Client, lifecycle: [], active_lifecycle: []) }

    before do
      Capybara.enable_aria_label = true
      allow(Dor::Workflow::Client).to receive(:new).and_return(workflow_client)
    end

    it 'the submit button exists' do
      visit apo_bulk_jobs_path(apo_id)
      expect(page).to have_link 'Submit new file ...', href: new_apo_upload_path(apo_id: 'druid:hv992yv2222')
      click_link 'Status information'
      expect(page).to have_content 'All spreadsheet rows converted to MODS'
    end
  end

  context 'when on the form for creating a new bulk job' do
    let(:bulk_job_data_path) { file_fixture('crowdsourcing_bridget_1.xml') }

    before do
      stub_request(:post, Settings.normalizer_url)
        .to_return(status: 200, body: bulk_job_data_path.read, headers: {})
    end

    it 'prevents choices from being made until the file is uploaded' do
      visit apo_bulk_jobs_path(apo_id)
      click_link 'Submit new file ...'

      expect(find('input#filetypes_1')).to be_disabled
      expect(find('input#filetypes_2')).to be_disabled
      expect(find('input#convert_only')).to be_disabled
      expect(find('input#note_text')).to be_disabled
      expect(find('button#spreadsheet_submit')).to be_disabled
      expect(find('button#spreadsheet_cancel')).not_to be_disabled

      # selecting a file to upload and selecting one of the radio buttons enables the submit button
      attach_file('spreadsheet_file', bulk_job_data_path)

      # Manually trigger update event on file submit field, since Capybara/Poltergeist doesn't seem to do it
      script = <<~JAVASCRIPT
        var event = document.createEvent('HTMLEvents');
        event.initEvent('change', true, false);
        var el = document.getElementById('spreadsheet_file');
        el.dispatchEvent(event);
      JAVASCRIPT
      page.execute_script(script)

      expect(page).to have_css('span#bulk-spreadsheet-warning', text: '', visible: false)
      expect(find('button#spreadsheet_submit')).to be_disabled
      expect(find('input#convert_only')).not_to be_disabled
      choose('convert_only')
      expect(find('button#spreadsheet_submit')).not_to be_disabled
      click_button('Submit')
      expect(page).to have_button('Delete')
      click_button('Delete', match: :first)
      expect(page).to have_content('Are you sure you want to delete the job directory and the files it contains?')
      within '.modal-dialog' do
        click_button('Delete')
      end
      expect(page).to have_content(/Bulk job for APO.+deleted\./)
    end

    it 'uploading a file with an invalid extension displays a warning' do
      visit apo_bulk_jobs_path(apo_id)
      click_link 'Submit new file ...'

      attach_file('spreadsheet_file', File.absolute_path(__FILE__))

      # Manually trigger update event on file submit field, since Capybara/Poltergeist doesn't seem to do it
      script = <<~JAVASCRIPT
        var event = document.createEvent('HTMLEvents');
        event.initEvent('change', true, false);
        var el = document.getElementById('spreadsheet_file');
        el.dispatchEvent(event);
      JAVASCRIPT
      page.execute_script(script)

      expect(page).to have_css('span#bulk-spreadsheet-warning',
                               text: 'Note: Only spreadsheets or XML files are allowed. Please check your selected file.')
    end
  end
end
