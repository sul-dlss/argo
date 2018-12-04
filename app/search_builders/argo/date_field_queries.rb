# frozen_string_literal: true

module Argo
  ##
  # Part of the Blacklight SearchBuilder
  module DateFieldQueries
    extend ActiveSupport::Concern

    ##
    # Removes raw Solr query in favor standard Solr filter query
    def add_date_field_queries(solr_parameters)
      return unless blacklight_params['f']

      solr_parameters[:fq] ||= []
      blacklight_params['f'].select { |k, _v| k =~ /.+_dt/ }.each do |key, values|
        values.each do |v|
          solr_parameters[:fq].delete("{!term f=#{key}}#{v}")
          solr_parameters[:fq] << "#{key}:#{v}"
        end
      end
    end
  end
end
