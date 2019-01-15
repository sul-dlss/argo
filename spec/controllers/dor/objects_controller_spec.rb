# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dor::ObjectsController, type: :controller do
  before do
    sign_in(create(:user))
  end

  let(:dor_registration) { { pid: 'abc' } }

  describe '#create' do
    it 'registers the object and reindexes the pid list' do
      expect(Dor::Services::Client.objects)
        .to receive(:register)
        .and_return(dor_registration)
      expect(Dor::IndexingService)
        .to receive(:reindex_pid_list)
        .with([dor_registration[:pid]], true) # commits reindex
      post :create
    end
  end
end
