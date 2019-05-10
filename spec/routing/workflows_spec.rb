# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkflowsController do
  describe 'routing' do
    it 'routes to to #facet' do
      expect(put: '/items/druid:hx908xy6904/workflows/accessionWF')
        .to route_to('workflows#update', item_id: 'druid:hx908xy6904', id: 'accessionWF')
    end
  end
end
