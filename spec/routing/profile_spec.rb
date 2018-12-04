# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ReportController do
  describe 'routing' do
    it 'routes to to #facet' do
      expect(get: '/profile/facet/topic_ssim')
        .to route_to('profile#facet', id: 'topic_ssim')
    end
  end
end
