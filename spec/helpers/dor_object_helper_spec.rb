# frozen_string_literal: true

require 'rails_helper'

class DummyClass
  include DorObjectHelper
end

describe DorObjectHelper, type: :helper do
  describe '#last_accessioned_version' do
    let(:druid) { 'oo000oo0000' }

    it 'uses PreservationClient' do
      allow(PreservationClient).to receive(:current_version).with(druid)
      DummyClass.new.last_accessioned_version(druid)
      expect(PreservationClient).to have_received(:current_version).with(druid)
    end
  end
end
