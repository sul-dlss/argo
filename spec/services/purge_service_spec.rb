# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PurgeService do
  describe '.purge' do
    subject(:purge) { described_class.purge(druid: 'druid:ab123cd4567', user_name: 'dijkstra') }

    let(:object_client) { instance_double(Dor::Services::Client::Object, destroy: true) }

    before do
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    end

    it 'removes the object' do
      purge
      expect(object_client).to have_received(:destroy)
    end
  end
end
