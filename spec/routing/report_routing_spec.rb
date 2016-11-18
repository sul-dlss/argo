require 'spec_helper'

RSpec.describe ReportController do
  describe 'routing' do
    it 'routes to to #facet' do
      expect(get: '/report/facet/topic_ssim')
        .to route_to('report#facet', id: 'topic_ssim')
    end
  end
end
