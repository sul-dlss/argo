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
  # @param [String] DRUID
  # @return [Array<String>] set of roles permitted by DRUID
  def roles(pid)
    druid = DruidTools::Druid.new(pid).druid
    @role_cache ||= {}
    return @role_cache[druid] if @role_cache[druid]
    # Try to retrieve a Solr doc for the DRUID
    obj_doc = Dor::SearchService.query('id:"' + druid + '"')['response']['docs'].first || {}
    return [] if obj_doc.empty?
    druid_roles = Set.new
    # Determine whether user has 'dor-apo-manager' role
    solr_apo_roles = %w(apo_role_group_manager_ssim apo_role_person_manager_ssim)
    druid_roles << 'dor-apo-manager' if solr_apo_roles.any? {|r| solr_role_allowed?(obj_doc, r)}
    # Check additional known roles
    known_roles.each do |role|
      solr_apo_roles = ["apo_role_#{role}_ssim", "apo_role_person_#{role}_ssim"]
      druid_roles << role if solr_apo_roles.any? {|r| solr_role_allowed?(obj_doc, r)}
    end
    # store and return an array of roles (Set.sort is an Array)
    @role_cache[druid] = druid_roles.sort
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

  # The convention is for boolean is_XYZ methods to be interrogative (end in "?")
  alias_method :is_admin?,   :is_admin
  alias_method :is_manager?, :is_manager
  alias_method :is_viewer?,  :is_viewer

  def login
    webauth ? webauth.login : sunetid
  end

  # Notes on definitions for known roles in dor-services:
  #
  # At present, there are a few methods that all do the same thing;
  # see all the `can_manage_*` methods in Dor::Governable, i.e.
  # https://github.com/sul-dlss/dor-services/blob/develop/lib/dor/models/governable.rb
  #
  # The upshot of this is that it’s not yet clear how Argo should query a Dor
  # object about management rights. That is, it’s not clear how granular the
  # management privilege should be. It seems reasonable, at present, to simply
  # query a Dor object using `dor_object.can_manage_item?` (without recourse to
  # `dor_object.can_manage_content?` etc.)
  #
  # When more granular management rights are required, this method will adapt
  # because the `permission` parameter can be changed as required.
  # Also, the ArgoHelper#render_buttons should be revised.

  # Authorize object management permissions using Argo user roles.
  #
  # @param dor_object [String|Dor::Base] Accepts a DRUID string or
  #                                      any subclass of Dor::Base
  # @param permission [String] dor_object.can_manage_{permission}?
  #                            The default is dor_object.can_manage_item?
  # @return [Boolean]
  def can_manage?(dor_object, permission = 'item')
    # Any administrator or manager viewer can manage any object.
    return true if is_admin || is_manager
    # Check user roles permitted to manage the object.
    permission_method = "can_manage_#{permission}?"
    request_object_permission(dor_object, permission_method)
  end

  # Authorize object view permissions using Argo user roles.
  #
  # @param dor_object [String|Dor::Base] Accepts a DRUID string or
  #                                      any subclass of Dor::Base
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

  # Do argo permissions allow viewing anything.
  # @return [Boolean]
  def can_view_something?
    is_admin || is_manager || is_viewer || permitted_apos.length > 0
  end

  private

  # Find a Dor object, whether the input is a DRUID, a PID or a Dor object.
  # @param druid [String|anything]
  #              DruidTools::Druid is used to parse String, which is
  #              then input for Dor.find to obtain a Dor object
  # @raises ArgumentError
  def get_dor_object(druid)
    if druid.is_a? String
      druid = DruidTools::Druid.new(druid).druid
      Dor.find(druid)
    else
      # Dor objects inherit from ActiveFedora::Base, so this could be checked
      # here and raise ArgumentError if 'druid' is not a Dor object.  However,
      # this can break specs that use a mock double.  So, if it's not a String,
      # just return it as is.
      druid
    end
  end

  # Authorize object permissions using Argo user roles.
  # First check permissions on the governing APO of the object.
  # If that fails and the object is an APO, let it authorize permission.
  #
  # @param dor_object [String|Dor::Base] Accepts a DRUID string or
  #                                      any subclass of Dor::Base
  # @param permission [String] dor_object.send(permission)
  # @return [Boolean]
  def request_object_permission(dor_object, permission)
    # Check that we can request a specific permission.  Note that this could
    # be more specific by checking that the `permission` method is defined in
    # Dor::Governable from dor-services, but that level of detail in this check
    # could break the flexibility of this method and dor-services designs.
    dor_object = get_dor_object(dor_object)
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
