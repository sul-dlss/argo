# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Count the members of a collection' do
  let(:user) { create(:user) }
  let(:collection) { FactoryBot.create_for_repository(:persisted_collection) }
  let(:rendered) do
    Capybara::Node::Simple.new(response.body)
  end

  before do
    sign_in user, groups: ['sdr:administrator-role']
    FactoryBot.create_for_repository(:persisted_item, collection_id: collection.externalIdentifier)
    FactoryBot.create_for_repository(:persisted_item, collection_id: collection.externalIdentifier)
  end

  it 'returns the count' do
    get "/collections/#{collection.externalIdentifier}/count"

    expect(response).to have_http_status(:ok)
    expect(rendered.find_css('turbo-frame#collection-member-count')).to be_present
    expect(rendered).to have_link '2', href: search_catalog_path(
      f: {
        is_member_of_collection_ssim: ["info:fedora/#{collection.externalIdentifier}"]
      }
    )
    expect(rendered.find_link('2')[:target]).to eq '_top'
  end
end
