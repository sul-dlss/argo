require 'spec_helper'

RSpec.describe SearchBuilder do
  let(:method_chain) { CatalogController.search_params_logic }
  let(:user_params) { Hash.new }
  let(:solr_params) { Hash.new }
  let(:context) { CatalogController.new }

  let(:search_builder) { described_class.new(method_chain, context) }

  subject { search_builder.with(user_params) }

  describe '#initialize' do
    it 'should have add_access_controls_to_solr_params in chain once' do
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
    it 'should have pids_only in chain once' do
      expect(subject.processor_chain)
        .to include :pids_only
      expect(subject.processor_chain
        .count { |x| x == :pids_only }).to eq 1
      new_search = described_class.new(subject.processor_chain, context)
      expect(new_search.processor_chain)
        .to include :pids_only
      expect(subject.processor_chain
        .count { |x| x == :pids_only }).to eq 1
    end
    it 'should have add_date_field_queries in chain once' do
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
