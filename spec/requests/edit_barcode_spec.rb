# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Edit barcode' do
  let(:user) { create(:user) }
  let(:cocina_model) { build(:dro_with_metadata, id: druid) }

  let(:druid) { 'druid:dc243mg0841' }

  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model, update: true) }
  let(:turbo_stream_headers) do
    { 'Accept' => "#{Mime[:turbo_stream]},#{Mime[:html]}",
      'Turbo-Frame' => 'edit_copyright' }
  end
  let(:version_service) { instance_double(VersionService, open?: true) }

  before do
    allow(VersionService).to receive(:new).and_return(version_service)
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    sign_in user, groups: ['sdr:administrator-role']
  end

  describe 'display the form' do
    it 'draws the form' do
      get "/items/#{druid}/edit_barcode", headers: turbo_stream_headers

      expect(response).to be_successful
    end
  end

  describe 'display the show view (after cancel)' do
    it 'draws the component' do
      get "/items/#{druid}/show_barcode", headers: turbo_stream_headers

      expect(response).to be_successful
    end
  end
end
