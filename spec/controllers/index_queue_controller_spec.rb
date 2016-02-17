require 'spec_helper'

describe IndexQueueController do
  describe 'GET depth' do
    let(:index_queue) { double('index_queue', depth: 100) }
    before :each do
      log_in_as_mock_user(subject)
    end
    it 'should return a depth from the IndexQueue class' do
      expect(IndexQueue).to receive(:new).and_return(index_queue)
      get :depth, format: :json
      expect(response.body).to eq '100'
    end
  end
end
