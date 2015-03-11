require 'spec_helper'

describe DiscoveryController, :type => :controller do
  describe ":data" do
    it 'should fetch json data with the gdor fields in it' do
      log_in_as_mock_user(subject)
      allow_any_instance_of(User).to receive(:groups).and_return(['sdr:administrator-role'])
      get :data, :format => :json, :rows =>5
      json_body=JSON.parse(response.body)
      expect(json_body['rows'].first.has_key?('sw_author_other_facet_facet')).to be true
    end
  end
end
