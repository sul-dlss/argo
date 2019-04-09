# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dor::ObjectsController, type: :controller do
  before do
    sign_in(create(:user))

    allow(Dor).to receive(:find).with(dor_registration[:pid]).and_return(mock_object)
  end

  let(:mock_object) { instance_double(Dor::Item, update_index: true) }
  let(:dor_registration) { { pid: 'abc' } }

  describe '#create' do
    it 'registers the object and reindexes the pid list' do
      expect(Dor::Services::Client.objects)
        .to receive(:register)
        .and_return(dor_registration)
      post :create
      expect(mock_object).to have_received(:update_index)
    end
  end
end
