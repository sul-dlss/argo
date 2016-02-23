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
      blacklight_params['f'].each do |query|
        if query[0] =~ /.+_dt/
          solr_parameters[:fq].delete("{!raw f=#{query[0]}}#{query[1][0]}")
          solr_parameters[:fq] << "#{query[0]}:#{query[1][0]}"
        end
      end
    end
  end
end
