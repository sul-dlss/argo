# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Count the members of an apo' do
  let(:user) { create(:user) }
  let(:ur_apo_id) { 'druid:hv992ry2431' }
  let(:rendered) do
    Capybara::Node::Simple.new(response.body)
  end

  before do
    blacklight_config = CatalogController.blacklight_config
    solr_conn = blacklight_config.repository_class.new(blacklight_config).connection
    # Ensure we start from fresh or the link text may not be what we expect
    solr_conn.delete_by_query("#{SolrDocument::FIELD_OBJECT_TYPE}:item OR #{SolrDocument::FIELD_OBJECT_TYPE}:collection")
    solr_conn.commit
    sign_in user, groups: ['sdr:administrator-role']
  end

  describe 'counting the collection members' do
    before do
      FactoryBot.create_for_repository(:persisted_collection)
      FactoryBot.create_for_repository(:persisted_collection)
    end

    it 'returns the count' do
      get "/apo/#{ur_apo_id}/count_collections"

      expect(response).to have_http_status(:ok)
      expect(rendered.find_css('turbo-frame#apo-collection-count')).to be_present
      expect(rendered).to have_link '2', href: search_catalog_path(
        f: {
          is_governed_by_ssim: ["info:fedora/#{ur_apo_id}"],
          SolrDocument::FIELD_OBJECT_TYPE => ['collection']
        }
      )
      expect(rendered.find_link('2')[:target]).to eq '_top'
    end
  end

  describe 'counting the item members' do
    let(:item) { FactoryBot.create_for_repository(:persisted_item) }
    let(:admin_policy_id) { item.administrative.hasAdminPolicy }

    it 'returns the count' do
      get "/apo/#{admin_policy_id}/count_items"

      expect(rendered.find_css('turbo-frame#apo-item-count')).to be_present
      expect(rendered).to have_link '1', href: search_catalog_path(
        f: {
          is_governed_by_ssim: ["info:fedora/#{admin_policy_id}"],
          SolrDocument::FIELD_OBJECT_TYPE => ['item']
        }
      )
      expect(rendered.find_link('1')[:target]).to eq '_top'
    end
  end
end
