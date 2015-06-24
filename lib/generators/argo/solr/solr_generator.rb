module Argo
  module Generators
    class SolrGenerator < Rails::Generators::Base
      source_root File.expand_path('../templates', __FILE__)

      attr_accessor :target_path
      attr_accessor :target_file

      desc "Creates configuration at #{@target_path}"
      argument :prod_solr, :type => :string, :default => 'http://your.production.solr-server.com/solr'

      def initialize(*args)
        super(*args)
        @target_file = 'solr.yml'
        @target_path = File.join('config', @target_file)
      end

      def create_config_file
        template "#{self.target_file}.erb", self.target_path
      end

      private

      def prodhost
        uri = URI.parse(prod_solr)
        uri = URI.parse('http://' + prod_solr) if uri.scheme.nil?
        uri
      end

    end
  end
end
