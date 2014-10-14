require 'spec_helper'

describe DiscoveryController do
  describe ":data" do
    it 'should fetch json data with the gdor fields in it' do
      log_in_as_mock_user(subject)
      User.any_instance.stub(:groups).and_return(['sdr:administrator-role'])
      get :data, :format => :json, :rows =>5
      json_body=JSON.parse(response.body)
      expect(json_body['rows'].first.has_key?('sw_author_other_facet_facet')).to be true
    end
  end
end
