# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SearchBuilder do
  subject { search_builder.with(user_params) }

  let(:user_params) { {} }
  let(:solr_params) { {} }
  let(:context) { CatalogController.new }

  let(:search_builder) { described_class.new(context) }

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
    it 'has pids_only in chain once' do
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
    it 'contains add_profile_queries once' do
      expect(subject.processor_chain)
        .to include :add_profile_queries
      expect(subject.processor_chain
        .count { |x| x == :add_profile_queries }).to eq 1
      new_search = described_class.new(subject.processor_chain, context)
      expect(new_search.processor_chain)
        .to include :add_profile_queries
      expect(subject.processor_chain
        .count { |x| x == :add_profile_queries }).to eq 1
    end
  end

  describe '#add_facet_paging_to_solr' do
    subject { search_builder.with(user_params).facet(facet) }

    let(:facet) { 'nonhydrus_collection_title_ssim' }

    it 'uses the :more_limit configuration to independently change the "more" size' do
      solr_params = {}

      subject.add_facet_paging_to_solr(solr_params)

      expect(solr_params).to include :"f.#{facet}.facet.limit" => 10000,
                                     :"f.#{facet}.facet.offset" => 0
    end
  end
end
