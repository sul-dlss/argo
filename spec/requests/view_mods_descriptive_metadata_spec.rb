# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'View MODS descriptive metadata' do
  let(:user) { create(:user) }

  let(:cocina_object) do
    build(:dro, id: druid, title: 'PROVINCIæ BOREALIS AMERICÆ NON ITA PRIDEM DETECTÆ AVT MAGIS AB EVROPÆIS EXCVLTÆ.')
  end
  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_object) }
  let(:druid) { 'druid:bc123df4567' }

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
