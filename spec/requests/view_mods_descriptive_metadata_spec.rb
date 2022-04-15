# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'View MODS descriptive metadata' do
  let(:user) { create(:user) }

  let(:object_client) { instance_double(Dor::Services::Client::Object, metadata:) }
  let(:metadata) { instance_double(Dor::Services::Client::Metadata, descriptive: xml) }
  let(:xml) do
    <<~XML
      <mods xmlns="http://www.loc.gov/mods/v3" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="3.3" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-3.xsd">
        <typeOfResource>cartographic</typeOfResource>
        <genre authority="marcgt">map</genre>
        <genre>Digital Maps</genre>
        <genre>Early Maps</genre>
        <identifier displayLabel="Original McLaughlin Book Number (1995 edition)" type="local">160</identifier>
        <titleInfo>
          <title>PROVINCI&#xE6; BOREALIS AMERIC&#xC6; NON ITA PRIDEM DETECT&#xC6; AVT MAGIS AB EVROP&#xC6;IS EXCVLT&#xC6;.</title>
        </titleInfo>
      </mods>
    XML
  end
  let(:druid) { 'druid:999' }

  before do
    sign_in user
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
  end

  it 'draws the page' do
    get "/items/#{druid}/metadata/descriptive"
    expect(response).to be_successful
    expect(response.body).to include 'PROVINCIæ BOREALIS AMERICÆ NON ITA PRIDEM DETECTÆ AVT MAGIS AB EVROPÆIS EXCVLTÆ.'
  end
end
