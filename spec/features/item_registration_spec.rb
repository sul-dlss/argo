# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Item registration page', js: true do
  let(:barcode) { '6772719-1001' }
  let(:user) { create(:user) }
  let(:blacklight_config) { CatalogController.blacklight_config }
  let(:solr_conn) { blacklight_config.repository_class.new(blacklight_config).connection }

  before do
    ResetSolr.reset_solr
    sign_in user, groups: ['sdr:administrator-role', 'dlss:developers']
  end

  # this mocks a failed registration response from DSA
  context 'failed registration' do
    let(:ur_apo_id) { 'druid:hv992ry2431' }
    let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model) }
    let(:cocina_model) do
      build(:admin_policy_with_metadata, registration_workflow: %w[dpgImageWF goobiWF])
    end

    before do
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    end

    it 'invokes item registration method with the expected values and relays errors properly' do
      visit registration_path
      select '[Internal System Objects]', from: 'Admin Policy' # "uber APO"
      select 'goobiWF', from: 'Initial Workflow'
      select 'book', from: 'Content Type'
      select 'left-to-right', from: 'Viewing Direction'

      fill_in 'Project Name', with: 'special division : project #4'
      fill_in 'tags_0', with: 'tag : test'

      # click the button to add a row for a new item
      click_button 'Add another row'
      find_all("tr.ui-widget-content[role='row']") # try to wait for the item entry row to show up, since it's added dynamically after clicking the add btn

      # fill out the barcode field
      find("td[aria-describedby='data_barcode_id']").click # the editable field isn't present till the table cell is clicked
      find("td[aria-describedby='data_barcode_id'] input[name='barcode_id']") # wait for the editable field to show up in the table cell
      fill_in 'barcode_id', with: barcode

      # fill out the source ID field
      find("td[aria-describedby='data_source_id']").click # the editable field isn't present till the table cell is clicked
      find("td[aria-describedby='data_source_id'] input[name='source_id']") # wait for the editable field to show up in the table cell
      fill_in 'source_id', with: 'source:id1'

      # fill out the label field
      find("td[aria-describedby='data_label']").click # the editable field isn't present till the table cell is clicked
      find("td[aria-describedby='data_label'] input[name='label']") # wait for the editable field to show up in the table cell
      fill_in 'label', with: 'object title'

      # Change focus off of the label
      find("td[aria-describedby='data_label'] input[name='label']").native.send_keys :tab

      registration_params = {}
      expect_any_instance_of(Dor::ObjectsController).to receive(:create) do |arg|
        # If parameter expectations are put in here, and an expectation fails, the controller
        # will respond with a 500 (because the failure produces an exception, and this block
        # is running in place of the mocked method).  But it won't result in a nice explanatory
        # test failure message (presumably because it's not executing and bubbling up within
        # the context of the test definition). So write to a var defined in the test and inspect
        # the var out there.
        registration_params.merge!(arg.params.to_unsafe_h)

        arg.render json: { error: 'errror' }.to_json, status: 500 # test error presentation
      end

      click_button 'Register'

      # This lets us test that a failed registration results in an exclamation icon on the item row.  But
      # it also forces capybara to wait for the Dor::ObjectsController#create call to finish, meaning the
      # block we fed to expect_any_instance_of (to mock #create) can set registration_params, allowing us
      # to check the params below.
      expect(page).to have_css('span.icon-exclamation-sign', visible: true, wait: 50)
      expect(registration_params).to include(
        'admin_policy' => ur_apo_id,
        'barcode_id' => barcode,
        'collection' => '',
        'label' => 'object title',
        'project' => 'special division : project #4',
        'access' => {
          'view' => 'world',
          'download' => 'world',
          'controlledDigitalLending' => 'false'
        },
        'source_id' => 'source:id1',
        'content_type' => 'https://cocina.sul.stanford.edu/models/book',
        'viewing_direction' => 'left-to-right',
        'tags' => ['', 'tag : test', '', '', '', '', '', '', '', '', '', ''],
        'workflow_id' => 'goobiWF'
      )
    end
  end

  # this successfully registers an object
  context 'successful registration' do
    let(:source_id) { "sul:#{SecureRandom.uuid}" }

    it 'register an item correctly' do
      visit registration_path
      select '[Internal System Objects]', from: 'Admin Policy' # "uber APO"
      select 'registrationWF', from: 'Initial Workflow'
      select 'book', from: 'Content Type'
      select 'left-to-right', from: 'Viewing Direction'
      select 'Stanford', from: 'View access'
      select 'Stanford', from: 'Download access'

      fill_in 'Project Name', with: 'X-Files'
      fill_in 'tags_0', with: 'i : believe'

      # click the button to add a row for a new item
      click_button 'Add another row'
      find_all("tr.ui-widget-content[role='row']") # try to wait for the item entry row to show up, since it's added dynamically after clicking the add btn

      # fill out the barcode field
      find("td[aria-describedby='data_barcode_id']").click # the editable field isn't present till the table cell is clicked
      find("td[aria-describedby='data_barcode_id'] input[name='barcode_id']") # wait for the editable field to show up in the table cell
      fill_in 'barcode_id', with: barcode

      # fill out the source ID field
      find("td[aria-describedby='data_source_id']").click # the editable field isn't present till the table cell is clicked
      find("td[aria-describedby='data_source_id'] input[name='source_id']") # wait for the editable field to show up in the table cell
      fill_in 'source_id', with: source_id

      # fill out the label field
      find("td[aria-describedby='data_label']").click # the editable field isn't present till the table cell is clicked
      find("td[aria-describedby='data_label'] input[name='label']") # wait for the editable field to show up in the table cell
      fill_in 'label', with: 'object title'

      # Change focus off of the label
      find("td[aria-describedby='data_label'] input[name='label']").native.send_keys :tab

      click_button 'Register'

      expect(page).to have_css('span.icon-ok-sign', visible: true, wait: 50) # registration succeeded checkmark

      find('td[aria-describedby=data_status][title=success]')
      object_druid = find('td[aria-describedby=data_druid]').text

      # Since we don't have rabbitMQ in the test suite, we have to fake it by indexing manually.
      Argo::Indexer.reindex_druid_remotely(object_druid)
      visit solr_document_path(object_druid)

      # now verify that registration succeeded by checking some metadata
      within_table('Overview') do
        expect(page).to have_css 'th', text: 'Status'
        expect(page).to have_css 'td', text: 'v1 Registered'
        expect(page).to have_css 'th', text: 'Access rights'
        expect(page).to have_css 'td', text: 'View: Stanford, Download: Stanford'
      end

      within_table('Details') do
        expect(page).to have_css 'th', text: 'Object type'
        expect(page).to have_css 'td', text: 'item'
        expect(page).to have_css 'th', text: 'Content type'
        expect(page).to have_css 'td', text: 'book'
        expect(page).to have_css 'th', text: 'Project'
        expect(page).to have_css 'td a', text: 'X-Files'
        expect(page).to have_css 'th', text: 'Source IDs'
        expect(page).to have_css 'td', text: source_id
        expect(page).to have_css 'th', text: 'Barcode'
        expect(page).to have_css 'td', text: barcode
        expect(page).to have_css 'th', text: 'Tags'
        expect(page).to have_css 'td a', text: 'Project : X-Files'
        expect(page).to have_css 'td a', text: 'i : believe'
        expect(page).to have_css 'td a', text: "Registered By : #{user.sunetid}"
      end
    end
  end
end
