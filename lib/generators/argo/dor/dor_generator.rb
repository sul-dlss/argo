module Argo
  module Generators
    class DorGenerator < Rails::Generators::Base
      source_root File.expand_path('../templates', __FILE__)

      attr_accessor :target_path
      attr_accessor :target_file

      desc "Creates configuration based on current Rails.env at #{@target_path}"
    # long_desc would be used if we switched the base to Thor
    #  long_desc <<-EOF
    #  The main purpose of this is to provide Continuous Integration testing a minimal config.
    #  That is to say, you may need to do more to setup development and production.
    #
    #EOF
      argument :workflow_server, :type => :string, :default => 'https://your.workflow-server.com/workflow'

      def initialize(*args)
        super(*args)
        @target_file = "dor_#{Rails.env}.rb"
        @target_path = File.join('config', 'environments', @target_file)
      end

      def create_config_file
        template "dor.rb.erb", self.target_path
      end

      private

      def workflow_url
        uri = URI.parse(workflow_server)
        uri = URI.parse('https://' + workflow_server) if uri.scheme.nil?
        uri
      end

    end
  end
end
