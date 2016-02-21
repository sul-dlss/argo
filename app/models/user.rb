class User < ActiveRecord::Base
  # Connects this user object to Blacklights Bookmarks and Folders.
  include Blacklight::User
  has_many :bulk_actions

  # The code base requires Arrays for these constants, for intersection ops.
  ADMIN_GROUPS = %w(workgroup:sdr:administrator-role).freeze
  MANAGER_GROUPS = %w(workgroup:sdr:manager-role).freeze
  VIEWER_GROUPS = %w(workgroup:sdr:viewer-role).freeze

  # TODO: redefine `KNOWN_ROLES` using Dor::Governable.
  # The KNOWN_ROLES should be consistent with Dor::Governable so that the
  # set intersections can work as required.
  # This depends on changes in dor-services, e.g.
  # https://github.com/sul-dlss/dor-services/pull/150
  # Dor::Governable::KNOWN_ROLES

  # @return [Array<String>] list of roles the user can adopt
  KNOWN_ROLES = %w(
    dor-apo-creator
    dor-apo-depositor
    dor-apo-manager
    dor-apo-metadata
    dor-apo-reviewer
    dor-apo-viewer
    sdr-administrator
    sdr-viewer
  ).freeze

  attr_accessor :webauth

  delegate :permitted_apos, :permitted_collections, to: :permitted_queries

  def permitted_queries
    @permitted_queries ||= PermittedQueries.new(groups, KNOWN_ROLES, is_admin)
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
    return [] if pid.blank?
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
    KNOWN_ROLES.each do |role|
      solr_apo_roles = ["apo_role_#{role}_ssim", "apo_role_person_#{role}_ssim"]
      pid_roles << role if solr_apo_roles.any? {|r| solr_role_allowed?(obj_doc, r)}
    end
    # store and return an array of roles (Set.sort is an Array)
    @role_cache[pid] = pid_roles.sort
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
    # remove any existing impersonation (see #groups below)
    @role_cache = {}
    @groups_to_impersonate = if grps.blank?
                               nil
                             else
                               grps.instance_of?(String) ? [grps] : grps
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

  # @return [Boolean] is the user a repository wide manager
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

  # Notes on definitions for known roles in dor-services:
  #
  # At present, there are a few methods that all do the same thing;
  # see all the `can_manage_*` methods in Dor::Governable, i.e.
  # https://github.com/sul-dlss/dor-services/blob/develop/lib/dor/models/governable.rb
  #
  # The upshot of this is that it is not yet clear how Argo should query a Dor
  # object about management rights. That is, it is not clear how granular the
  # management privilege should be. The consensus from discussions is to use a
  # default query for `dor_object.can_manage_item?` (without recourse to
  # `dor_object.can_manage_content?` etc.)
  #
  # When more granular permissions are required, these methods can adapt
  # because the `permission` parameter can be changed as required.

  # Authorize object administration permissions using Argo user roles.
  # This includes User#is_admin, it excludes User#is_manager;
  # otherwise permissions are determined by the object.
  #
  # @param dor_object [Dor::Base] Accepts any Dor::Governable object
  # @param permission [String] dor_object.can_manage_{permission}?
  #                            The default is dor_object.can_manage_item?
  # @return [Boolean]
  def can_admin?(dor_object, permission = 'item')
    # Any administrator can manage any object.
    return true if is_admin
    # Check user roles permitted to manage the object.
    permission_method = "can_manage_#{permission}?"
    request_object_permission(dor_object, permission_method)
  end

  # Authorize object management permissions using Argo user roles.
  # This includes User#is_admin and User#is_manager;
  # otherwise permissions are determined by the object.
  #
  # @param dor_object [Dor::Base] Accepts any Dor::Governable object
  # @param permission [String] dor_object.can_manage_{permission}?
  #                            The default is dor_object.can_manage_item?
  # @return [Boolean]
  def can_manage?(dor_object, permission = 'item')
    # Any administrator or manager can manage any object.
    return true if is_admin || is_manager
    # Check user roles permitted to manage the object.
    permission_method = "can_manage_#{permission}?"
    request_object_permission(dor_object, permission_method)
  end

  # Authorize object view permissions using Argo user roles.
  # This includes User#is_admin, User#is_manager, and User#is_viewer;
  # otherwise permissions are determined by the object.
  #
  # @param dor_object [Dor::Base] Accepts any Dor::Governable object
  # @param permission [String] dor_object.can_view_{permission}?
  #                            The default is dor_object.can_view_metadata?
  # @return [Boolean]
  def can_view?(dor_object, permission = 'metadata')
    # Any administrator, manager or viewer can view any object.
    return true if is_admin || is_manager || is_viewer
    # Check user roles permitted to view the object.
    permission_method = "can_view_#{permission}?"
    request_object_permission(dor_object, permission_method)
  end

  private

  # Authorize object permissions using Argo user roles.
  # First check permissions on the governing APO of the object.
  # If that fails and the object is an APO, let it authorize permission.
  #
  # @param dor_object [Dor::Base] Accepts any Dor::Governable object
  # @param permission [String] dor_object.send(permission)
  # @return [Boolean]
  def request_object_permission(dor_object, permission)
    # Check that we can request a specific permission.  Note that this could
    # be more specific by checking that the `permission` method is defined in
    # Dor::Governable from dor-services, but that level of detail in this check
    # could break the flexibility of this method and dor-services designs.
    unless dor_object.respond_to? permission
      raise ArgumentError.new("DOR object doesn't respond to: #{permission}")
    end
    # The authorization is first requested using the governing APO.
    apo = dor_object.admin_policy_object
    if apo
      return true if dor_object.send(permission, roles(apo.pid))
    end
    # Failing that, if the object is an APO, it can grant permission.
    if dor_object.is_a? Dor::AdminPolicyObject
      return true if dor_object.send(permission, roles(dor_object.pid))
    end
    false
  end
end
