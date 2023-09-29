# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'BulkActions::CollectionJobs' do
  let(:rendered) do
    Capybara::Node::Simple.new(response.body)
  end

  describe 'GET #new' do
    let(:permitted_queries) { instance_double(PermittedQueries, permitted_collections: collections) }
    let(:collections) do
      [
        ['None', ''],
        ['Dummy Collection 1', 'druid:123'],
        ['Dummy Collection 2', 'druid:456']
      ]
    end

    before do
      sign_in build(:user), groups: ['sdr:administrator-role']
      allow(PermittedQueries).to receive(:new).and_return(permitted_queries)
    end

    it 'draws the form' do
      get '/bulk_actions/collection_job/new'

      expect(rendered).to have_css 'textarea[name="druids"]'
      expect(rendered).to have_css 'textarea[name="description"]'
      expect(rendered).to have_css 'select[name="new_collection_id"]'
      expect(rendered).to have_css 'select[name="new_collection_id"] option[value="druid:123"]'
      expect(rendered).to have_css 'select[name="new_collection_id"] option[value="druid:456"]'
    end
  end
end
