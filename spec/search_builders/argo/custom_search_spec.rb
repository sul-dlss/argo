# frozen_string_literal: true

require 'rails_helper'

##
# Fake class for testing module
class TestClass
  include Argo::CustomSearch
end

RSpec.describe Argo::CustomSearch do
  subject { TestClass.new }

  describe '#strip_qualified_druids' do
    let(:solr_params) { { q: query } }

    context 'when the query is not a single druid' do
      let(:query) { 'Infinite Jest' }

      it 'does not alter the query' do
        subject.strip_qualified_druids(solr_params)
        expect(solr_params).to eq(q: 'Infinite Jest')
      end
    end

    context 'when the query is a single, unprefixed druid' do
      let(:query) { 'bc123df4567' }

      it 'does not alter the query' do
        subject.strip_qualified_druids(solr_params)
        expect(solr_params).to eq(q: 'bc123df4567')
      end
    end

    context 'when the query is a single, prefixed druid' do
      let(:query) { 'druid:bc123df4567' }

      it 'removes the druid prefix from the query' do
        subject.strip_qualified_druids(solr_params)
        expect(solr_params).to eq(q: 'bc123df4567')
      end
    end
  end
end
