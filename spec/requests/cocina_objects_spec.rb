# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cocina objects' do
  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    sign_in build(:user), groups: []
  end

  let(:rendered) do
    Capybara::Node::Simple.new(response.body)
  end

  let(:cocina_object) { build(:dro) }

  context 'when the head cocina object' do
    let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_object) }

    before do
      allow(Argo.verifier).to receive(:verify).and_return({ druid: 'druid:kv840xx0000' })
    end

    it 'renders a turbo-frame' do
      get '/items/skret-t0k3n/cocina_object'
      expect(response).to have_http_status(:ok)
      expect(rendered.find_css('turbo-frame#cocina_object')).to be_present
    end
  end

  context 'when a user version' do
    let(:object_client) { instance_double(Dor::Services::Client::Object, user_version: user_version_client) }

    let(:user_version_client) { instance_double(Dor::Services::Client::UserVersion, find: cocina_object) }

    before do
      allow(Argo.verifier).to receive(:verify).and_return({ druid: 'druid:kv840xx0000', user_version_id: 2 })
    end

    it 'renders a turbo-frame' do
      get '/items/skret-t0k3n/cocina_object'
      expect(response).to have_http_status(:ok)
      expect(rendered.find_css('turbo-frame#cocina_object')).to be_present
      expect(user_version_client).to have_received(:find).with(2)
    end
  end

  context 'when a system version' do
    let(:object_client) { instance_double(Dor::Services::Client::Object, version: version_client) }

    let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, find: cocina_object) }

    before do
      allow(Argo.verifier).to receive(:verify).and_return({ druid: 'druid:kv840xx0000', version_id: 2 })
    end

    it 'renders a turbo-frame' do
      get '/items/skret-t0k3n/cocina_object'
      expect(response).to have_http_status(:ok)
      expect(rendered.find_css('turbo-frame#cocina_object')).to be_present
      expect(version_client).to have_received(:find).with(2)
    end
  end
end
