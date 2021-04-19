# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Register an Agreement', js: true do
  include Dry::Monads[:result]
  let(:user) { create(:user) }
  let(:conn) { instance_double(SdrClient::Connection) }
  let(:blacklight_config) { CatalogController.blacklight_config }
  let(:solr_conn) { blacklight_config.repository_class.new(blacklight_config).connection }

  before do
    sign_in user, groups: ['sdr:administrator-role']
  end

  it 'creates an agreement' do
    # go to the registration form and fill it in
    visit new_agreement_path
    fill_in 'Title', with: 'Agreement Title'
    fill_in 'Source', with: "sauce:#{SecureRandom.alphanumeric(10)}"
    attach_file 'Agreement File (1/2)', 'spec/fixtures/crowdsourcing_bridget_1.xlsx', make_visible: true

    click_button 'Create Agreement'

    expect(page).to have_text 'Agreement created'
    expect(page).to have_text 'Agreement Title'
  end
end
