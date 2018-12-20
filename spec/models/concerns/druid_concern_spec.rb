# frozen_string_literal: true

require 'spec_helper'

describe DruidConcern do
  let(:document) { SolrDocument.new(document_attributes) }
  let(:document_attributes) { { id: 'druid:abc123456' } }

  describe '#druid' do
    it 'returns the druid' do
      expect(document.druid).to eq 'abc123456'
    end
  end
end
