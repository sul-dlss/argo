# frozen_string_literal: true

# Functions for querying solr
module Mods
  class SolrService
    include Singleton

    def options
      { url: Settings.solrizer_url }
    end

    def conn
      @conn ||= RSolr.connect options
    end

    class << self
      delegate :conn, to: :instance

      # @param [Hash] options
      def get(query, args = {})
        args = args.merge(q: query, wt: :json)
        conn.get('select', params: args)
      end
    end
  end
end
