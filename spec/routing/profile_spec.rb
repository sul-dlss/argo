# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReportController do
  describe 'routing' do
    it 'routes to to #facet' do
      expect(get: "/profile/facet/#{SolrDocument::FIELD_TOPIC}")
        .to route_to('profile#facet', id: SolrDocument::FIELD_TOPIC)
    end
  end
end
