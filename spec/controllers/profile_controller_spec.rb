# frozen_string_literal: true

require 'spec_helper'

describe ProfileController do
  it 'is a subclass of CatalogController' do
    expect(described_class.superclass).to eq CatalogController
  end
end
