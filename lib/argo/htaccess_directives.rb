# frozen_string_literal: true

module Argo
  # Create an .htaccess directives for the provided workgroups
  class HtaccessDirectives
    DEFAULT_HTACCESS = ['AuthType shibboleth',
                        'Require shib-attr eduPersonEntitlement dlss:argo-access'].freeze

    def self.write(groups)
      new(groups).write
    end

    def initialize(groups)
      @groups = groups
    end

    attr_reader :groups

    # @return [String] the body of the htaccess file
    def write
      directives = group_directives
      return '' if directives.empty?
      (default_directives + directives).sort.join("\n")
    end

    private

    # @return [Array] the second part of the groups that have "workgroup:" as a prefix
    def filter_groups(groups)
      groups.select { |v| v =~ /^workgroup:/ }.map { |v| v.split(/:/, 2).last }
    end

    # @return [Array]
    def group_directives
      priv_groups.uniq.map do |group_name|
        "Require shib-attr eduPersonEntitlement #{group_name}"
      end
    end

    # @return [Array]
    def default_directives
      # Read directives from shared configs
      DEFAULT_HTACCESS + defaults_from_file
    end

    # @return [Array]
    def defaults_from_file
      (File.readlines(Rails.root.join('config', 'default_htaccess_directives')) || [])
    end

    # @return [Array] the filtered group names and the built-in groups
    def priv_groups
      return [] if groups.empty?
      filter_groups(groups) +
        User::ADMIN_GROUPS +
        User::MANAGER_GROUPS +
        User::VIEWER_GROUPS
    end
  end
end
