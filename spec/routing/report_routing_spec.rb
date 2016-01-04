require 'spec_helper'

RSpec.describe ReportController do
  describe 'routing' do
    it 'routes to to #facet' do
      expect(get: '/report/topic_ssim/facet')
        .to route_to('report#facet', id: 'topic_ssim')
    end
  end
end
