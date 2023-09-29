# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Item registration page', :js do
  let(:barcode) { '6772719-1001' }
  let(:source_id) { "sul:#{SecureRandom.uuid}" }
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
    let(:object_client) { instance_double(Dor::Services::Client::Object, find_lite: cocina_model, find: cocina_model) }
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
      fill_in 'Tags', with: 'tag : test'

      fill_in 'Barcode', with: barcode
      fill_in 'Source ID', with: 'source:id1'
      fill_in 'Label', with: 'object title'

      registration_params = {}
      expect_any_instance_of(RegistrationForm).to receive(:validate) do |form, attributes|
        # If parameter expectations are put in here, and an expectation fails, the controller
        # will respond with a 500 (because the failure produces an exception, and this block
        # is running in place of the mocked method).  But it won't result in a nice explanatory
        # test failure message (presumably because it's not executing and bubbling up within
        # the context of the test definition). So write to a var defined in the test and inspect
        # the var out there.
        registration_params = attributes
        form.errors.add(:save, 'Conflict')

        false
      end

      click_button 'Register'

      # This lets us test that a failed registration results in an exclamation icon on the item row.  But
      # it also forces capybara to wait for the Dor::ObjectsController#create call to finish, meaning the
      # block we fed to expect_any_instance_of (to mock #create) can set registration_params, allowing us
      # to check the params below.
      expect(page).to have_css('.alert', text: 'Conflict')
      expect(registration_params).to include(
        'admin_policy' => ur_apo_id,
        'collection' => '',
        'workflow_id' => 'goobiWF',
        'view_access' => 'world',
        'download_access' => 'world',
        'controlled_digital_lending' => 'false',
        'content_type' => 'https://cocina.sul.stanford.edu/models/book',
        'viewing_direction' => 'left-to-right',
        'project' => 'special division : project #4',
        'tags_attributes' => {
          '0' => {
            'name' => 'tag : test'
          },
          '1' => {
            'name' => ''
          },
          '2' => {
            'name' => ''
          },
          '3' => {
            'name' => ''
          },
          '4' => {
            'name' => ''
          },
          '5' => {
            'name' => ''
          }
        },
        'items_attributes' => {
          '0' => {
            'source_id' => 'source:id1',
            'catalog_record_id' => '',
            'label' => 'object title',
            'barcode' => barcode
          }
        }
      )
    end
  end

  # this successfully registers an object
  context 'successful registration' do
    it 'register an item correctly' do
      visit registration_path
      select '[Internal System Objects]', from: 'Admin Policy' # "uber APO"
      select 'registrationWF', from: 'Initial Workflow'
      select 'book', from: 'Content Type'
      select 'left-to-right', from: 'Viewing Direction'
      select 'Stanford', from: 'View access'
      select 'Stanford', from: 'Download access'

      fill_in 'Project Name', with: 'X-Files'
      fill_in 'Tags', with: 'i : believe'

      fill_in 'Barcode', with: barcode
      fill_in 'Source ID', with: source_id
      fill_in 'Label', with: 'object title'

      click_button 'Register'

      expect(page).to have_content 'Items successfully registered.'

      druid_link = find('td > a')

      # NOTE: Unless we force a reindex here, this spec is flappy (example RSpec seed: 39128)
      Argo::Indexer.reindex_druid_remotely(druid_link['href'].split('/').last)

      druid_link.click

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

  context 'invalid catalog_record_id' do
    it 'does not register' do
      visit registration_path
      select '[Internal System Objects]', from: 'Admin Policy' # "uber APO"
      select 'registrationWF', from: 'Initial Workflow'
      select 'book', from: 'Content Type'
      select 'left-to-right', from: 'Viewing Direction'
      select 'Stanford', from: 'View access'
      select 'Stanford', from: 'Download access'

      fill_in 'Project Name', with: 'X-Files'
      fill_in 'Tags', with: 'i : believe'

      fill_in CatalogRecordId.label, with: 'not_a_catkey'
      fill_in 'Source ID', with: source_id
      fill_in 'Label', with: 'object title'

      click_button 'Register'

      expect(page).to have_css('.invalid')
      expect(page).not_to have_content 'Items successfully registered.'
    end
  end

  context 'invalid barcode' do
    it 'does not register' do
      visit registration_path
      select '[Internal System Objects]', from: 'Admin Policy' # "uber APO"
      select 'registrationWF', from: 'Initial Workflow'
      select 'book', from: 'Content Type'
      select 'left-to-right', from: 'Viewing Direction'
      select 'Stanford', from: 'View access'
      select 'Stanford', from: 'Download access'

      fill_in 'Project Name', with: 'Y-Files'
      fill_in 'Tags', with: 'vinsky : believes'

      fill_in 'Barcode', with: 'not_a_barcode'
      fill_in 'Source ID', with: source_id
      fill_in 'Label', with: 'object title'

      click_button 'Register'

      expect(page).to have_css('.invalid')
      expect(page).not_to have_content 'Items successfully registered.'
    end
  end
end
