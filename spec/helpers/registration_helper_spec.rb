# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RegistrationHelper do
  describe '#valid_content_types' do
    it 'returns the expected content types in the expected order' do
      expect(valid_content_types).to eq ['Book (ltr)', 'Book (rtl)', 'File', 'Image', 'Map', 'Media', '3D', 'Document', 'Geo', 'Webarchive-seed']
    end
  end
end
