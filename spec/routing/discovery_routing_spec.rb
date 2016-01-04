require 'spec_helper'

RSpec.describe DiscoveryController do
  describe 'routing' do
    it 'routes to to #facet' do
      expect(get: '/discovery/topic_ssim/facet')
        .to route_to('discovery#facet', id: 'topic_ssim')
    end
  end
end
