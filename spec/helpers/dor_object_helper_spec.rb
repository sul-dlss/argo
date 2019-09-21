# frozen_string_literal: true

require 'rails_helper'

class DummyClass
  include DorObjectHelper
end

RSpec.describe DorObjectHelper, type: :helper do
  describe '#last_accessioned_version' do
    let(:druid) { 'oo000oo0000' }

    it 'uses preservation-client gem' do
      allow(Preservation::Client.objects).to receive(:current_version).with(druid)
      DummyClass.new.last_accessioned_version(druid)
      expect(Preservation::Client.objects).to have_received(:current_version).with(druid)
    end
  end
end
