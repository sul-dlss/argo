class User < ActiveRecord::Base
  # Connects this user object to Blacklights Bookmarks and Folders.
  include Blacklight::User

  ADMIN_GROUPS =   ['workgroup:sdr:administrator-role', 'workgroup:dlss:dor-admin']
  MANAGER_GROUPS = ['workgroup:sdr:manager-role', 'workgroup:dlss:dor-manager']
  VIEWER_GROUPS =  ['workgroup:sdr:viewer-role', 'workgroup:dlss:dor-viewer']

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
    apo_roles = %w(apo_role_group_manager_ssim apo_role_person_manager_ssim)
    druid_roles << 'dor-apo-manager' if apo_roles.any? {|r| role_allowed?(obj_doc, r)}
    # Check additional known roles
    known_roles.each do |role|
      apo_roles = ["apo_role_#{role}_ssim", "apo_role_person_#{role}_ssim"]
      druid_roles << role if apo_roles.any? {|r| role_allowed?(obj_doc, r)}
    end
    # store and return an array of roles (Set.sort is an Array)
    @role_cache[druid] = druid_roles.sort
  end

  # @return [Array<String>] list of roles the user can adopt
  def known_roles
    @known_roles ||= %w(
      dor-administrator
      dor-apo-creator
      dor-apo-depositor
      dor-apo-manager
      dor-apo-metadata
      dor-apo-reviewer
      dor-apo-viewer
      dor-viewer
      sdr-administrator
      sdr-viewer
    )
  end

  # Validate a user belongs to a workgroup allowed to access a DOR object
  # @param dor_doc [Hash] A Solr document for a DOR object
  # @param roles [Array<String>] Roles to be validated for the DOR object
  def role_allowed?(solr_doc, role)
    # solr_doc[role] returns an array of groups permitted to adopt the role
    !(solr_doc[role] & groups).blank?
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

  # Validate access permissions using Argo user roles. If that fails, check the
  # APO role permissions.  If the object is an APO, first check permissions on
  # the governing APO of this APO object. As a last resort, check the object
  # roles when this object is an APO.
  # @param dor_object [String|Dor::Base] Accepts a DRUID string or
  #                                      any subclass of Dor::Base
  # @return [Boolean]
  def can_manage_object?(dor_object)
    dor_object = parse_object(dor_object)
    pid = dor_object.pid
    apo_pid = dor_object.admin_policy_object.pid
    manager_access = is_admin || is_manager
    manager_access ||= dor_object.can_manage_item?(roles(apo_pid))
    manager_access ||= dor_object.can_manage_content?(roles(apo_pid))
    manager_access ||= dor_object.is_a?(Dor::AdminPolicyObject) && dor_object.can_manage_item?(roles(pid))
    manager_access ||= dor_object.is_a?(Dor::AdminPolicyObject) && dor_object.can_manage_content?(roles(pid))
    manager_access
  end

  # Validate access permissions using Argo user roles. If that fails, check the
  # APO role permissions.  If the object is an APO, first check permissions on
  # the governing APO of this APO object. As a last resort, check the object
  # roles when this object is an APO.
  # @param dor_object [String|Dor::Base] Accepts a DRUID string or
  #                                      any subclass of Dor::Base
  # @return [Boolean]
  def can_view_object?(dor_object)
    dor_object = parse_object(dor_object)
    return true if can_manage_object?(dor_object)
    pid = dor_object.pid
    apo_pid = dor_object.admin_policy_object.pid
    view_access = is_viewer
    view_access ||= dor_object.can_view_content?(roles(apo_pid))
    view_access ||= dor_object.is_a?(Dor::AdminPolicyObject) && dor_object.can_view_content?(roles(pid))
    view_access
  end

  # Do argo permissions allow viewing anything.
  # @return [Boolean]
  def can_view_something?
    is_admin || is_manager || is_viewer || permitted_apos.length > 0
  end

  private

  # Find a Dor object, whether the input is a DRUID, a PID or a Dor object.
  # @param druid [String|ActiveFedora::Base]
  #              DruidTools::Druid is used to parse String, which is
  #              then input for Dor.find to obtain a Dor object
  #              Dor objects inherit from ActiveFedora::Base
  # @raises ArgumentError
  def parse_object(druid)
    if druid.is_a? String
      find_druid(druid)
    elsif druid.is_a? ActiveFedora::Base
      druid
    else
      raise ArgumentError
    end
  end

end
