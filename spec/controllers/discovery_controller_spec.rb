require 'spec_helper'

describe DiscoveryController, :type => :controller do
  before :each do
    log_in_as_mock_user(subject)
    allow_any_instance_of(User).to receive(:groups).and_return(['sdr:administrator-role'])
  end

  describe ':data' do
    it 'should fetch json data with the gdor fields in it' do
      get :data, :format => :json, :rows => 5
      json_body = JSON.parse(response.body)
      expect(json_body).to match a_hash_including('rows')
      expect(json_body['rows']).not_to be_nil
      expect(json_body['rows'].first).to match a_hash_including('sw_format_tesim')
    end
  end

  describe 'download' do
    it 'should download valid CSV data' do
      get :download
      expect(response.status).to eq(200)
      expect(response.header['Content-Disposition']).to eq('attachment; filename=report.csv')
      expect { CSV.parse(response.body) }.not_to raise_error
    end
  end
end
