require 'spec_helper'

RSpec.describe Dor::ObjectsController, type: :controller do
  before do
    log_in_as_mock_user
  end

  let(:dor_registration) { { pid: 'abc' } }
  describe '#create' do
    it 'does something' do
      expect(Dor::RegistrationService)
        .to receive(:create_from_request)
        .and_return(dor_registration)
      expect(Dor::IndexingService)
        .to receive(:reindex_pid_list)
        .with([dor_registration[:pid]], true) # commits reindex
      post :create
    end
  end
end
