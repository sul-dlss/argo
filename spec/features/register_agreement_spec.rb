# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Register an Agreement', js: true do
  include Dry::Monads[:result]
  let(:user) { create(:user) }
  let(:conn) { instance_double(SdrClient::Connection) }
  let(:druid) { 'druid:xx999bb3333' }
  let(:blacklight_config) { CatalogController.blacklight_config }
  let(:solr_conn) { blacklight_config.repository_class.new(blacklight_config).connection }

  before do
    sign_in user, groups: ['sdr:administrator-role']
#    allow(SdrClient::Login).to receive(:run).and_return(Success())
#    allow(SdrClient::Connection).to receive(:new).and_return(conn)
#    allow(SdrClient::Deposit::UploadFiles).to receive(:upload)
#      .and_return([SdrClient::Deposit::Files::DirectUploadResponse.new(filename: 'crowdsourcing_bridget_1.xlsx', signed_id: '9999999')])
#    allow(SdrClient::Deposit::CreateResource).to receive(:run).and_return(1234)
#    allow(SdrClient::BackgroundJobResults).to receive(:show).and_return({ 'status' => 'complete', 'output' => { 'druid' => druid } })
#    solr_conn.add(id: druid,
#                  objectType_ssim: 'agreement',
#                  obj_label_tesim: 'Agreement title')
#    solr_conn.commit
  end

  it 'creates an agreement' do
    # go to the registration form and fill it in
    visit new_agreement_path
    fill_in 'Title', with: 'Agreement Title'
    fill_in 'Source', with: "sauce:#{SecureRandom.alphanumeric(10)}"

    attach_file 'Agreement file', 'spec/fixtures/crowdsourcing_bridget_1.xlsx', make_visible: true

    click_button 'Create Agreement'

    expect(page).to have_text 'Agreement created'
    expect(page).to have_text 'Agreement Title'
  end
end
