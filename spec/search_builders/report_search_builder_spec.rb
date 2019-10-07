# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReportSearchBuilder do
  subject { report_search_builder.with(user_params) }

  let(:user_params) { {} }
  let(:solr_params) { {} }
  let(:context) { CatalogController.new }

  let(:report_search_builder) { described_class.new(context) }

  describe '#initialize' do
    it 'has add_access_controls_to_solr_params in chain once' do
      expect(subject.processor_chain)
        .to include :add_access_controls_to_solr_params
      expect(subject.processor_chain
        .count { |x| x == :add_access_controls_to_solr_params }).to eq 1
      new_search = described_class.new(subject.processor_chain, context)
      expect(new_search.processor_chain)
        .to include :add_access_controls_to_solr_params
      expect(subject.processor_chain
        .count { |x| x == :add_access_controls_to_solr_params }).to eq 1
    end
    it 'has add_date_field_queries in chain once' do
      expect(subject.processor_chain)
        .to include :add_date_field_queries
      expect(subject.processor_chain
        .count { |x| x == :add_date_field_queries }).to eq 1
      new_search = described_class.new(subject.processor_chain, context)
      expect(new_search.processor_chain)
        .to include :add_date_field_queries
      expect(subject.processor_chain
        .count { |x| x == :add_date_field_queries }).to eq 1
    end
  end
end
