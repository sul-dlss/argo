# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Constants do
  it 'has correct CONTENT_TYPES defined' do
    expect(Constants::CONTENT_TYPES).to include(
      'image', 'book', 'file', 'map', 'media', '3d'
    )
  end
  it 'has correct RESOURCE_TYPES defined' do
    expect(Constants::RESOURCE_TYPES).to include(
      'image', 'page', 'file', 'audio', 'video', '3d'
    )
  end
end
