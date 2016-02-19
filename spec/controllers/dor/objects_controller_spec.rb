require 'spec_helper'

describe Dor::ObjectsController, :type => :controller do
  before do
    log_in_as_mock_user(subject)
  end
  let(:dor_registration) { { pid: 'abc' } }
  describe '#create' do
    it 'does something' do
      expect(Dor::RegistrationService)
        .to receive(:create_from_request)
        .and_return(dor_registration)
      post :create
    end
  end
end
