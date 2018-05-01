# frozen_string_literal: true

require 'argo/htaccess_directives'

module Argo
  # Create an .htaccess file for the provided workgroups
  class HtaccessWriter
    FILE = Rails.root.join('public', '.htaccess').freeze

    def self.write(groups, directive_writer: Argo::HtaccessDirectives)
      new(groups, directive_writer).write
    end

    def initialize(groups, directive_writer)
      @groups = groups
      @body = directive_writer.write(groups)
    end

    attr_reader :groups, :body

    # @return [String] the body of the htaccess file
    def write
      return if body.empty?
      File.open(FILE, 'w') do |htaccess|
        htaccess.puts body
      end
      File.unlink('public/auth/.htaccess') if File.exist?('public/auth/.htaccess')
    end
  end
end
