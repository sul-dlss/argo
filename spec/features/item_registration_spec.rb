# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Item registration page', js: true do
  let(:barcode) { '6772719-1001' }
  let(:user) { create(:user) }
  let(:ur_apo_id) { 'druid:hv992ry2431' }
  let(:blacklight_config) { CatalogController.blacklight_config }
  let(:solr_conn) { blacklight_config.repository_class.new(blacklight_config).connection }
  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model) }
  let(:cocina_model) do
    build(:admin_policy_with_metadata, registration_workflow: %w[dpgImageWF goobiWF])
  end

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    ResetSolr.reset_solr
    sign_in user, groups: ['sdr:administrator-role', 'dlss:developers']
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
      'rights' => 'default',
      'source_id' => 'source:id1',
      'content_type' => 'https://cocina.sul.stanford.edu/models/book',
      'viewing_direction' => 'left-to-right',
      'tag' => ['', 'tag : test', '', '', '', '', '', '', '', '', '', ''],
      'workflow_id' => 'goobiWF'
    )
  end
end
