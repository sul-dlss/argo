# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Item registration page', js: true do
  let(:user) { create(:user) }

  before do
    sign_in user, groups: ['sdr:administrator-role', 'dlss:developers']
    allow_any_instance_of(RegistrationController).to receive(:workflows_for_apo).and_return([])
    allow_any_instance_of(RegistrationController).to receive(:workflows_for_apo).with('druid:hv992ry2431').and_return(['dpgImageWF', 'goobiWF'])
  end

  it 'loads page with registration form' do
    visit register_items_path
    expect(page).to have_css '#gbox_data'
  end

  it 'invokes item registration method with the expected values and relays errors properly' do
    visit register_items_path

    select '[Internal System Objects]', from: 'apo_id' # "uber APO", druid:hv992ry2431

    find("option[value='goobiWF']")
    select 'goobiWF', from: 'workflow_id'

    fill_in 'tags_0', with: 'tag : test'

    # click the button to add a row for a new item
    find('button.action-add', text: 'Add Row').click
    find_all("tr.ui-widget-content[role='row']") # try to wait for the item entry row to show up, since it's added dynamically after clicking the add btn

    # fill out the source ID field
    find("td[aria-describedby='data_source_id']").click # the editable field isn't present till the table cell is clicked
    find("td[aria-describedby='data_source_id'] input[name='source_id']") # wait for the editable field to show up in the table cell
    fill_in 'source_id', with: 'source:id1'

    # fill out the label field
    find("td[aria-describedby='data_label']").click # the editable field isn't present till the table cell is clicked
    find("td[aria-describedby='data_label'] input[name='label']") # wait for the editable field to show up in the table cell
    fill_in 'label', with: 'object title'

    registration_params = {}
    expect_any_instance_of(Dor::ObjectsController).to receive(:create) do |arg|
      # If parameter expectations are put in here, and an expectation fails, the controller
      # will respond with a 500 (because the failure produces an exception, and this block
      # is running in place of the mocked method).  But it won't result in a nice explanatory
      # test failure message (presumably because it's not executing and bubbling up within
      # the context of the test definition).  So write to a var defined in the test and inpsect
      # the var out there.
      registration_params.merge!(arg.params.to_unsafe_h)

      arg.render json: { error: 'errror' }.to_json, status: 500 # test error presentation
    end

    find('#jqg_data_0').set(true)
    find('button.action-lock').click
    find('button.action-register').click

    # This lets us test that a failed registration results in an exclamation icon on the item row.  But
    # it also forces capybara to wait for the Dor::ObjectsController#create call to finish, meaning the
    # block we fed to expect_any_instance_of (to mock #create) can set registration_params, allowing us
    # to check the params below.
    expect(page).to have_css('span.icon-exclamation-sign', visible: true)
    expect(registration_params).to include(
      'object_type' => 'item',
      'admin_policy' => 'druid:hv992ry2431',
      'workflow_id' => 'goobiWF',
      'metadata_source' => 'label',
      'label' => 'object title',
      'tag' => ['Process : Content Type : Book (ltr)', 'tag : test', "Registered By : #{user.sunetid}"],
      'rights' => 'default',
      'collection' => '',
      'source_id' => 'source:id1'
    )
  end
end
