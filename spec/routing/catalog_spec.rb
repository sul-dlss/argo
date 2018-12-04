# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CatalogController do
  describe 'routing' do
    it 'routes to #index' do
      expect(get: '/catalog').to route_to('catalog#index')
    end
    it 'routes to #show' do
      expect(get: '/view/druid:xyz')
        .to route_to('catalog#show', id: 'druid:xyz')
    end

    it 'routes to #dc' do
      expect(get: '/view/druid:xyz/dc')
        .to route_to('catalog#dc', id: 'druid:xyz')
    end

    it 'routes to #ds' do
      expect(get: '/view/druid:xyz/ds/identityMetadata')
        .to route_to('catalog#ds', id: 'druid:xyz', dsid: 'identityMetadata')
    end

    it 'routes to #manage_release' do
      expect(get: '/view/druid:xyz/manage_release')
        .to route_to('catalog#manage_release', id: 'druid:xyz')
    end

    context 'redirections' do
      include RSpec::Rails::RequestExampleGroup

      it 'redirects to /view' do
        get '/catalog/druid:xyz'
        expect(response).to redirect_to('/view/druid:xyz')
      end
    end
  end
end
