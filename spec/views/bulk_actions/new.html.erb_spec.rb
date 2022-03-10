# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'bulk_actions/new.html.erb' do
  let(:user_groups) { %w[dlss-developers top-secret-clearance] }
  let(:apo_list) { [['APO 1', 'druid:123'], ['APO 2', 'druid:234']] }
  let(:query_params) { { q: 'testing' } }
  let(:blacklight_config) { Blacklight::Configuration.new }
  let(:search_state) { Blacklight::SearchState.new(query_params, blacklight_config) }
  let(:current_user) { double(sunetid: 'esnowden', groups: user_groups, permitted_collections: collections) }
  let(:collections) do
    [
      ['None', ''],
      ['Dummy Collection 1', 'druid:123'],
      ['Dummy Collection 2', 'druid:456']
    ]
  end

  before do
    @form = BulkActionForm.new(create(:bulk_action), groups: user_groups)
    allow(view).to receive(:current_user).and_return(current_user)
    allow(view).to receive(:apo_list).with(user_groups).and_return(apo_list)
    allow(view).to receive(:search_state).and_return(search_state)
    render
  end

  it 'form by default has action_type selected' do
    expect(rendered)
      .to have_css 'select option:first-child[value="DescmetadataDownloadJob"]'
  end

  describe 'common form fields' do
    it 'has proper form input values' do
      expect(rendered).to have_css 'textarea[name="bulk_action[pids]"]'
      expect(rendered).to have_css 'textarea[name="bulk_action[description]"]'
    end
  end

  describe 'Release Object Job form' do
    it 'has proper form input values' do
      expect(rendered).to have_css 'select option[value="ReleaseObjectJob"]'
      expect(rendered).to have_css 'input[type="radio"][value="true"][checked="checked"][name="bulk_action[manage_release][tag]"]'
      expect(rendered).to have_css 'input[type="radio"][value="false"][name="bulk_action[manage_release][tag]"]'
      expect(rendered).to have_css 'select[name="bulk_action[manage_release][to]"]'
      expect(rendered).to have_css 'option[value="Searchworks"]'
      expect(rendered).to have_css 'input[value="self"][type="hidden"][name="bulk_action[manage_release][what]"]', visible: false
      expect(rendered).to have_css 'input[value="esnowden"][type="hidden"][name="bulk_action[manage_release][who]"]', visible: false
    end
  end

  describe 'Set License and Rights Statements Job form' do
    it 'has proper form input values' do
      expect(rendered).to have_css 'input[type="checkbox"][value="1"][name="bulk_action[set_license_and_rights_statements][use_statement_option]"]'
      expect(rendered).to have_css 'textarea[name="bulk_action[set_license_and_rights_statements][use_statement]"]'
      expect(rendered).to have_css 'input[type="checkbox"][value="1"][name="bulk_action[set_license_and_rights_statements][copyright_statement_option]"]'
      expect(rendered).to have_css 'textarea[name="bulk_action[set_license_and_rights_statements][copyright_statement]"]'
      expect(rendered).to have_css 'input[type="checkbox"][value="1"][name="bulk_action[set_license_and_rights_statements][license_option]"]'
      expect(rendered).to have_css 'select[name="bulk_action[set_license_and_rights_statements][license]"]'
      expect(rendered).to have_css 'option[value=""]'
      expect(rendered).to have_css 'option[value="https://creativecommons.org/licenses/by-sa/3.0/legalcode"]'
    end
  end

  describe 'Update governing APO Job form' do
    it 'has proper form input values' do
      expect(rendered).to have_css 'select option[value="SetGoverningApoJob"]'
      expect(rendered).to have_css 'select[name="bulk_action[set_governing_apo][new_apo_id]"] option[value="druid:234"]'
    end
  end

  describe 'Reindex Job form' do
    it 'has proper form input values' do
      expect(rendered).to have_css 'select option[value="RemoteIndexingJob"]'
    end
  end

  describe 'Export Tags form' do
    it 'has proper form input values' do
      expect(rendered).to have_css 'select option[value="ExportTagsJob"]'
    end
  end

  describe 'Set Catkeys and Barcodes Job form' do
    it 'has proper form input values' do
      expect(rendered).to have_css 'input[type="checkbox"][value="1"][name="bulk_action[set_catkeys_and_barcodes][use_catkeys_option]"]'
      expect(rendered).to have_css 'textarea[name="bulk_action[set_catkeys_and_barcodes][catkeys]"]'
      expect(rendered).to have_css 'input[type="checkbox"][value="1"][name="bulk_action[set_catkeys_and_barcodes][use_barcodes_option]"]'
      expect(rendered).to have_css 'textarea[name="bulk_action[set_catkeys_and_barcodes][barcodes]"]'
    end
  end

  describe 'Set Catkeys and Barcodes CSV Job form' do
    it 'has proper form input values' do
      expect(rendered).to have_css 'input[type="file"][name="bulk_action[set_catkeys_and_barcodes_csv][csv_file]"]'
    end
  end

  describe 'Manage Embargoes Job form' do
    it 'has proper form input values' do
      expect(rendered).to have_css 'input[type="file"][name="bulk_action[manage_embargo][csv_file]"]'
    end
  end

  describe 'Set Collection Job form' do
    it 'has proper form input values' do
      expect(rendered).to have_css 'select option[value="SetCollectionJob"]'
      expect(rendered).to have_css 'select[name="bulk_action[set_collection][new_collection_id]"]'
      expect(rendered).to have_css 'select[name="bulk_action[set_collection][new_collection_id]"] option[value="druid:123"]'
      expect(rendered).to have_css 'select[name="bulk_action[set_collection][new_collection_id]"] option[value="druid:456"]'
    end
  end
end
