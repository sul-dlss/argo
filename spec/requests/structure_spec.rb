# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Structure' do
  before do
    allow(Argo.verifier).to receive(:verified).and_return({ druid: 'druid:kv840xx0000' })
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    sign_in build(:user), groups: []
  end

  let(:rendered) do
    Capybara::Node::Simple.new(response.body)
  end

  let(:object_client) do
    instance_double(Dor::Services::Client::Object, find: cocina_item,
                                                   user_version: user_version_client, version: version_client)
  end
  let(:user_version_client) { nil }
  let(:version_client) { nil }
  let(:cocina_item) { build(:dro_with_metadata) }

  context 'when a user version is not specified' do
    it 'renders a turbo-frame' do
      get '/items/skret-t0k3n/structure'
      expect(response).to have_http_status(:ok)
      expect(rendered.find_css('turbo-frame#structure')).to be_present
    end
  end

  context 'when a user version is specified' do
    let(:user_version_client) { instance_double(Dor::Services::Client::UserVersion, find: cocina_item) }
    let(:user_version) { 2 }

    it 'renders a turbo-frame' do
      get "/items/skret-t0k3n/public_version/#{user_version}/structure"
      expect(response).to have_http_status(:ok)
      expect(rendered.find_css('turbo-frame#structure')).to be_present
    end
  end

  context 'when a version is specified' do
    let(:user_version_client) { instance_double(Dor::Services::Client::ObjectVersion, find: cocina_item) }
    let(:version) { 2 }

    it 'renders a turbo-frame' do
      get "/items/skret-t0k3n/version/#{version}/structure"
      expect(response).to have_http_status(:ok)
      expect(rendered.find_css('turbo-frame#structure')).to be_present
    end
  end
end
