# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CreativeCommonsLicenseService do
  describe '#property' do
    subject(:property) { described_class.property('by_sa') }

    it 'returns a term' do
      expect(property.deprecation_warning).to match(/typo/)
      expect(property.key).to eq 'by_sa'
    end
  end
end
