require 'spec_helper'

RSpec.describe IndexQueueController do
  describe 'GET depth' do
    before do
      sign_in create(:user)
    end

    let(:index_queue) { double('index_queue', depth: 100) }
    it 'returns a depth from the IndexQueue class' do
      expect(IndexQueue).to receive(:new).and_return(index_queue)
      get :depth, params: { format: :json }
      expect(response.body).to eq '100'
    end
  end
end
