require 'spec_helper'

describe IndexQueueController do
  describe 'GET depth' do
    let(:index_queue) { double('index_queue', depth: 100) }
    it 'should return a depth from the IndexQueue class' do
      allow(subject).to receive(:webauth).
        and_return(double(:webauth_user, login: 'sunetid', logged_in?: true))
      expect(IndexQueue).to receive(:new).and_return(index_queue)
      get :depth, format: :json
      expect(response.body).to eq '100'
    end
  end
end
