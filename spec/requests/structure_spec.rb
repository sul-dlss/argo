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

  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_item) }
  let(:cocina_item) { build(:dro_with_metadata) }

  it 'renders a turbo-frame' do
    get '/items/skret-t0k3n/structure'
    expect(response).to have_http_status(:ok)
    expect(rendered.find_css('turbo-frame#structure')).to be_present
  end
end
