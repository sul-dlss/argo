# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'View descriptive metadata' do
  let(:user) { create(:user) }

  let(:cocina_object) do
    build(:dro, id: druid, title: 'PROVINCIæ BOREALIS AMERICÆ NON ITA PRIDEM DETECTÆ AVT MAGIS AB EVROPÆIS EXCVLTÆ.')
  end
  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_object, user_version: user_version_client, version: version_client) }
  let(:user_version_client) { nil }
  let(:version_client) { nil }
  let(:druid) { 'druid:bc123df4567' }

  before do
    sign_in user
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
  end

  it 'draws the page' do
    get "/items/#{druid}/metadata/descriptive"
    expect(response).to be_successful
    expect(response.body).to include 'PROVINCIæ BOREALIS AMERICÆ NON ITA PRIDEM DETECTÆ AVT MAGIS AB EVROPÆIS EXCVLTÆ'
  end

  context 'when a user version' do
    let(:cocina_object) do
      build(:dro_with_metadata, id: druid, title: 'PROVINCIæ BOREALIS AMERICÆ NON ITA PRIDEM DETECTÆ AVT MAGIS AB EVROPÆIS EXCVLTÆ.', version: user_version.to_i)
    end
    let(:user_version_client) { instance_double(Dor::Services::Client::UserVersion, find: cocina_object) }
    let(:user_version) { '2' }

    it 'displays the user version descriptive metadata' do
      get "/items/#{druid}/public_version/2/metadata/descriptive"
      expect(response).to be_successful
      expect(response.body).to include 'PROVINCIæ BOREALIS AMERICÆ NON ITA PRIDEM DETECTÆ AVT MAGIS AB EVROPÆIS EXCVLTÆ'
      expect(user_version_client).to have_received(:find).with(user_version)
    end
  end

  context 'when a version' do
    let(:cocina_object) do
      build(:dro_with_metadata, id: druid, title: 'PROVINCIæ BOREALIS AMERICÆ NON ITA PRIDEM DETECTÆ AVT MAGIS AB EVROPÆIS EXCVLTÆ.', version: version.to_i)
    end
    let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, find: cocina_object) }
    let(:version) { '2' }

    it 'displays the version descriptive metadata' do
      get "/items/#{druid}/version/2/metadata/descriptive"
      expect(response).to be_successful
      expect(response.body).to include 'PROVINCIæ BOREALIS AMERICÆ NON ITA PRIDEM DETECTÆ AVT MAGIS AB EVROPÆIS EXCVLTÆ'
      expect(version_client).to have_received(:find).with(version)
    end
  end
end
