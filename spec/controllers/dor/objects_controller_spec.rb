# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dor::ObjectsController, type: :controller do
  before do
    sign_in(create(:user))

    allow(Dor).to receive(:find).with(dor_registration[:pid]).and_return(mock_object)
  end

  let(:mock_object) { instance_double(Dor::Item, update_index: true) }
  let(:dor_registration) { { pid: 'abc' } }

  describe '#create' do
    context 'when register is successful' do
      it 'registers the object' do
        expect(Dor::Services::Client.objects)
          .to receive(:register)
          .and_return(dor_registration)
        post :create
        expect(response).to be_redirect
      end
    end

    context 'when register is a conflict' do
      let(:message) { "Conflict: 409 (An object with the source ID 'sul:36105226711146' has already been registered" }

      before do
        allow(Dor::Services::Client.objects)
          .to receive(:register)
          .and_raise(Dor::Services::Client::UnexpectedResponse, message)
      end

      it 'shows an error' do
        post :create
        expect(response.status).to eq 409
        expect(response.body).to eq message
      end
    end
  end
end
