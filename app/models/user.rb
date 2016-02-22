class User < ActiveRecord::Base
  # Connects this user object to Blacklights Bookmarks and Folders.
  include Blacklight::User
  has_many :bulk_actions

  # The code base requires Arrays for these constants, for intersection ops.
  ADMIN_GROUPS = %w(workgroup:sdr:administrator-role).freeze
  MANAGER_GROUPS = %w(workgroup:sdr:manager-role).freeze
  VIEWER_GROUPS = %w(workgroup:sdr:viewer-role).freeze

  attr_accessor :webauth

  delegate :permitted_apos, :permitted_collections, to: :permitted_queries

  def permitted_queries
    @permitted_queries ||= PermittedQueries.new(groups, known_roles, is_admin)
  end

  def self.find_or_create_by_webauth(webauth)
    result = find_or_create_by(:sunetid => webauth.login)
    result.webauth = webauth
    result
  end

  def self.find_or_create_by_remoteuser(username)
    find_or_create_by(:sunetid => username)
  end

  def to_s
    return sunetid unless webauth
    webauth.attributes['DISPLAYNAME'] || webauth.login
  end

  # Queries Solr for a given record, returning synthesized role strings that are defined. Searches:
  # (1) for User by sunet id
  # (2) groups actually contains the sunetid, so it is just looking at different solr fields
  # NOTE: includes legacy roles that have to be translated
  # @param [String] Object identifier (PID)
  # @return [Array<String>] set of roles permitted for PID
  def roles(pid)
    raise ArgumentError.new('Invalid PID') if pid.blank?
    @role_cache ||= {}
    return @role_cache[pid] if @role_cache[pid]
    # Try to retrieve a Solr doc
    obj_doc = Dor::SearchService.query('id:"' + pid + '"')['response']['docs'].first || {}
    return [] if obj_doc.empty?
    pid_roles = Set.new
    # Determine whether user has 'dor-apo-manager' role
    solr_apo_roles = %w(apo_role_group_manager_ssim apo_role_person_manager_ssim)
    pid_roles << 'dor-apo-manager' if solr_apo_roles.any? {|r| solr_role_allowed?(obj_doc, r)}
    # Check additional known roles
    known_roles.each do |role|
      solr_apo_roles = ["apo_role_#{role}_ssim", "apo_role_person_#{role}_ssim"]
      pid_roles << role if solr_apo_roles.any? {|r| solr_role_allowed?(obj_doc, r)}
    end
    # store and return an array of roles (Set.sort is an Array)
    @role_cache[pid] = pid_roles.sort
  end

  # TODO: try to redefine `known_roles` using Dor::Governable.
  # The known_roles should be consistent with Dor::Governable so that the
  # set intersections can work as required.
  # This depends on changes in dor-services, such as
  # https://github.com/sul-dlss/dor-services/pull/150
  # For example:
  # def known_roles
  #   @known_roles ||= Dor::Permissable::KNOWN_ROLES
  # end

  # @return [Array<String>] list of roles the user can adopt
  def known_roles
    @known_roles ||= %w(
      dor-apo-creator
      dor-apo-depositor
      dor-apo-manager
      dor-apo-metadata
      dor-apo-reviewer
      dor-apo-viewer
      sdr-administrator
      sdr-viewer
    )
  end

  # Validate a user belongs to a workgroup allowed to access a DOR object
  # @param dor_doc [Hash] A Solr document for a DOR object
  # @param role [String] Role to be validated for the DOR object
  def solr_role_allowed?(solr_doc, solr_role)
    # solr_doc[solr_role] returns an array of groups permitted to adopt the role
    !(solr_doc[solr_role] & groups).blank?
  end

  # Allow a repository admin to see the repository with different permissions
  # @param grps [Array<String>|String|nil] set of groups
  def set_groups_to_impersonate(grps)
    if grps.blank? # blank is falsy values like: nil, '', []
      # remove impersonation (see #groups below)
      @role_cache = {}
      @groups_to_impersonate = nil
    elsif grps.is_a? Array
      @role_cache = {}
      @groups_to_impersonate = grps
    elsif grps.is_a? String
      @role_cache = {}
      @groups_to_impersonate = [grps]
    else
      raise ArgumentError.new("Cannot accept #{grps.class} argument")
    end
  end

  def groups
    return @groups_to_impersonate unless @groups_to_impersonate.blank?
    @groups ||= begin
      perm_keys = ["sunetid:#{login}"]
      return perm_keys unless webauth && webauth.privgroup.present?
      perm_keys + webauth.privgroup.split(/\|/).map {|g| "workgroup:#{g}"}
    end
  end

  # @return [Boolean] is the user a repository wide administrator
  def is_admin
    !(groups & ADMIN_GROUPS).blank?
  end

  # @return [Boolean] is the user a repo wide manager
  def is_manager
    !(groups & MANAGER_GROUPS).blank?
  end

  # @return [Boolean] is the user a repository wide viewer
  def is_viewer
    !(groups & VIEWER_GROUPS).blank?
  end

  # https://github.com/bbatsov/ruby-style-guide#alias-method-lexically
  # The convention is for boolean is_XYZ methods to be interrogative (end in "?")
  alias is_admin? is_admin
  alias is_manager? is_manager
  alias is_viewer? is_viewer

  def login
    webauth ? webauth.login : sunetid
  end

  ##
  # @return [Boolean]
  def can_view_something?
    is_admin || is_manager || is_viewer || permitted_apos.length > 0
  end
end
